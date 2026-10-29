import AppKit
import CSMC
import SwiftUI

// `Fanbar --set auto|max|<rpm>` writes the fan keys and exits. The app runs itself that way under `sudo -n`,
// since SMC writes need root.
@main enum Entry {
    static func main() {
        let args = CommandLine.arguments
        if args.count == 3, args[1] == "--set" { exit(Fans.set(args[2]) ? 0 : 1) }
        NSApplication.shared.setActivationPolicy(.accessory)
        FanbarApp.main()
    }
}

enum SMC {
    static func value(_ key: String) -> Double? {
        var type = [CChar](repeating: 0, count: 5), b = [UInt8](repeating: 0, count: 32)
        guard smc_read(key, &type, &b) == 0 else { return nil }
        switch String(cString: type) {
        case "flt ": return Double(Float(bitPattern: UInt32(b[0]) | UInt32(b[1]) << 8 | UInt32(b[2]) << 16 | UInt32(b[3]) << 24))
        case "ui8 ": return Double(b[0])
        default: return nil
        }
    }

    static func write(_ key: String, _ bytes: [UInt8]) -> Bool { smc_write(key, bytes, UInt32(bytes.count)) == 0 }

    static func keys(prefixes: [String]) -> [String] {
        (0..<smc_count()).compactMap { i in
            var k = [CChar](repeating: 0, count: 5)
            guard smc_key_at(i, &k) == 0 else { return nil }
            let key = String(cString: k)
            return prefixes.contains { key.hasPrefix($0) } ? key : nil
        }
    }
}

enum Fans {
    static var count: Int { Int(SMC.value("FNum") ?? 0) }
    static func range(_ i: Int) -> ClosedRange<Double> { (SMC.value("F\(i)Mn") ?? 0)...(SMC.value("F\(i)Mx") ?? 0) }

    static func set(_ mode: String) -> Bool {
        (0..<count).allSatisfy { i in
            if mode == "auto" { return SMC.write("F\(i)md", [0]) }
            let r = range(i)
            let rpm = mode == "max" ? r.upperBound : min(max(Double(mode) ?? r.lowerBound, r.lowerBound), r.upperBound)
            return SMC.write("F\(i)md", [1]) && SMC.write("F\(i)Tg", withUnsafeBytes(of: Float(rpm).bitPattern.littleEndian, Array.init))
        }
    }
}

final class Model: ObservableObject {
    @Published var mode = UserDefaults.standard.string(forKey: "mode") ?? "auto"
    @Published var rpm: [Int] = []
    @Published var cpuW: Double?
    @Published var pGHz: Double?
    @Published var sGHz: Double?
    @Published var pressure: String?
    @Published var die: Double?
    @Published var battery: Double?
    @Published var otherControl = false
    let range = Fans.range(0)
    private var dieKeys: [String] = [], batteryKeys: [String] = []
    private var timer: Timer?, powermetrics: Process?

    init() {
        apply(mode)
        DispatchQueue.global().async {
            let die = SMC.keys(prefixes: ["Tp", "Tg", "Tm"]), battery = SMC.keys(prefixes: ["TB"])
            DispatchQueue.main.async { self.dieKeys = die; self.batteryKeys = battery }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            apply(mode)
        }
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.stop()
            Self.runRoot("auto")?.waitUntilExit()
        }
    }

    func apply(_ mode: String) {
        self.mode = mode
        UserDefaults.standard.set(mode, forKey: "mode")
        Self.runRoot(mode)
    }

    @discardableResult static func runRoot(_ mode: String) -> Process? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", Bundle.main.executablePath!, "--set", mode]
        return (try? p.run()) == nil ? nil : p
    }

    // Sampling runs only while the panel is open.
    func start() {
        readSMC()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.readSMC() }
        startPowermetrics()
    }

    func stop() {
        timer?.invalidate()
        powermetrics?.terminate()
        powermetrics = nil
    }

    private func readSMC() {
        rpm = (0..<Fans.count).map { Int(SMC.value("F\($0)Ac") ?? 0) }
        let maxOf = { (keys: [String]) in keys.compactMap(SMC.value).filter { $0 > 1 && $0 < 150 }.max() }
        die = maxOf(dieKeys)
        battery = maxOf(batteryKeys)
        otherControl = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.crystalidea.macsfancontrol" }
    }

    private func startPowermetrics() {
        let p = Process(), pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", "/usr/bin/powermetrics", "-i", "1000", "-f", "plist", "--samplers", "cpu_power,thermal"]
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        var buffer = Data()
        pipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            let chunk = h.availableData
            if chunk.isEmpty { h.readabilityHandler = nil; return }
            buffer.append(chunk)
            while let end = buffer.firstIndex(of: 0) {
                let sample = buffer[buffer.startIndex..<end]
                buffer = Data(buffer[(end + 1)...])
                guard let plist = try? PropertyListSerialization.propertyList(from: sample, format: nil) as? [String: Any] else { continue }
                DispatchQueue.main.async { self?.update(plist) }
            }
        }
        try? p.run()
        powermetrics = p
    }

    private func update(_ plist: [String: Any]) {
        let proc = plist["processor"] as? [String: Any] ?? [:]
        let clusters = proc["clusters"] as? [[String: Any]] ?? []
        func ghz(_ prefix: String) -> Double? {
            let f = clusters.filter { ($0["name"] as? String)?.hasPrefix(prefix) == true }.compactMap { $0["freq_hz"] as? Double }
            return f.isEmpty ? nil : f.reduce(0, +) / Double(f.count) / 1e9
        }
        cpuW = (proc["cpu_power"] as? Double).map { $0 / 1000 }
        pGHz = ghz("P")
        sGHz = ghz("S")
        pressure = plist["thermal_pressure"] as? String
    }
}

struct FanbarApp: App {
    @StateObject private var model = Model()

    var body: some Scene {
        MenuBarExtra("Fanbar", systemImage: "fan") { Panel(model: model) }
            .menuBarExtraStyle(.window)
    }
}

struct Panel: View {
    @ObservedObject var model: Model
    @State private var rpm = 2000.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Fans").bold()
                Spacer()
                Text(model.rpm.map(String.init).joined(separator: " / ") + " rpm").monospacedDigit()
            }
            Text(modeLabel).font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Quiet") { model.apply("2000") }
                Button("Fast") { model.apply("max") }
                Button("Stock") { model.apply("auto") }
            }
            HStack {
                Slider(value: $rpm, in: model.range) { editing in
                    if !editing { model.apply(String(Int(rpm))) }
                }
                Text("\(Int(rpm))").monospacedDigit().frame(width: 40, alignment: .trailing)
            }
            if model.otherControl {
                Text("Macs Fan Control is running and will override these.").font(.caption).foregroundStyle(.orange)
            }
            Divider()
            Grid(alignment: .leading, verticalSpacing: 4) {
                row("CPU power", model.cpuW.map { String(format: "%.1f W", $0) })
                row("P-cores", model.pGHz.map { String(format: "%.2f GHz", $0) })
                row("S-cores", model.sGHz.map { String(format: "%.2f GHz", $0) })
                row("Hottest die", model.die.map { String(format: "%.0f °C", $0) })
                row("Battery", model.battery.map { String(format: "%.1f °C", $0) })
                row("Throttling", model.pressure)
            }
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding(12)
        .frame(width: 250)
        .onAppear { model.start() }
        .onChange(of: model.mode, initial: true) {
            if let n = Double(model.mode) { rpm = n }
        }
        .onDisappear { model.stop() }
    }

    private var modeLabel: String {
        switch model.mode {
        case "auto": "Stock (Apple's curve)"
        case "max": "Max"
        default: "Manual \(model.mode) rpm"
        }
    }

    private func row(_ label: String, _ value: String?) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            Text(value ?? "…").monospacedDigit().frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
