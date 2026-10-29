import GhostFibers from '@/components/GhostFibers';

const REPO = 'https://github.com/hkay-dev/fanbar';
const STILL = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const SUDOERS =
  '%admin ALL=(root) NOPASSWD: /Applications/Fanbar.app/Contents/MacOS/Fanbar --set *, /usr/bin/powermetrics, /usr/bin/pmset -b powermode *, /usr/bin/pmset -c powermode *';

function Code({ children }) {
  return (
    <pre className="code">
      <code>{children}</code>
    </pre>
  );
}

export default function App() {
  return (
    <>
      <div className="backdrop" aria-hidden="true">
        <GhostFibers glowColor="#3ee0b0" secondaryColor="#ff9a3d" gradient="along" speed={0.35} brightness={0.85} vignette={0.5} paused={STILL} />
      </div>

      <header className="bar wrap">
        <a className="brand" href="#top">
          <img src="/icon.svg" alt="" width="32" height="32" />
          Fanbar
        </a>
        <a className="link" href={REPO}>Source on GitHub</a>
      </header>

      <main id="top">
        <section className="hero wrap">
          <div className="hero-copy">
            <h1>Fan control and energy mode, in your menu bar.</h1>
            <p className="lede">
              Fanbar is an extremely small, simple tool. Set your fan speed, switch the energy mode, and watch what it does to
              power, clocks and temperature. Nothing more, nothing less.
            </p>
            <p className="note">Tested only on an M5 Max running macOS 27.</p>
            <div className="actions">
              <a className="button primary" href="#run">Get it running</a>
              <a className="button" href={REPO}>Read the source</a>
            </div>
          </div>
          <figure className="shot">
            <img src="/panel.svg" alt="The Fanbar panel: fan presets, an rpm slider, the energy mode switch and live readings" width="270" height="393" />
          </figure>
        </section>

        <section className="wrap section">
          <h2>What it does</h2>
          <dl className="facts">
            <div>
              <dt>Fans</dt>
              <dd>Quiet, Fast or Stock, or any speed on the slider. Stock hands control back to Apple's own curve.</dd>
            </div>
            <div>
              <dt>Energy mode</dt>
              <dd>Low Power, Automatic or High Power, the same modes as System Settings, for the power source you're on.</dd>
            </div>
            <div>
              <dt>Readings</dt>
              <dd>CPU power, P-core and S-core clocks, the hottest die, battery temperature and whether the Mac is throttling.</dd>
            </div>
          </dl>
        </section>

        <section className="wrap section">
          <h2>Read this first</h2>
          <p className="body">
            Fanbar is for power users. There's no installer, no download and no support. Writing fan speeds, reading
            power and changing the energy mode all need root, so you decide how much access to give it. The whole app is
            about 380 lines of Swift and C. Read it before you hand it root.
          </p>
        </section>

        <section id="run" className="wrap section">
          <h2>Get it running</h2>

          <div className="step">
            <h3><span>1</span>Build it</h3>
            <p>You need macOS 14 or later, Xcode and <code>jq</code>. The script builds the app, signs it and puts it in Applications.</p>
            <Code>{`git clone ${REPO}.git
cd fanbar
SIGN_IDENTITY=- ./scripts/ship.sh`}</Code>
          </div>

          <div className="step">
            <h3><span>2</span>Pick how it's signed</h3>
            <div className="options">
              <div className="option">
                <h4>Ad-hoc</h4>
                <p>
                  <code>SIGN_IDENTITY=-</code> signs it with no certificate. It runs fine on the Mac that built it, and
                  that's all most people need.
                </p>
              </div>
              <div className="option">
                <h4>Your own self-signed certificate</h4>
                <p>Gives every rebuild the same identity, so macOS sees it as the same app each time.</p>
                <ol>
                  <li>Open Keychain Access, then Keychain Access › Certificate Assistant › Create a Certificate.</li>
                  <li>Give it a name, set Identity Type to Self Signed Root and Certificate Type to Code Signing.</li>
                  <li>Open the new certificate, expand Trust and set Code Signing to Always Trust.</li>
                  <li>Build with its name: <code>SIGN_IDENTITY="Your Name" ./scripts/ship.sh</code></li>
                </ol>
              </div>
            </div>
          </div>

          <div className="step">
            <h3><span>3</span>Pick how it gets root</h3>
            <p>
              Fanbar asks for root with <code>sudo -n</code>, which never prompts. If sudo would need a password, that
              part just doesn't work. Pick the option that you're comfortable with.
            </p>
            <div className="options">
              <div className="option">
                <h4>Readings only</h4>
                <p>
                  Do nothing. Fan rpm, the hottest die and battery temperature still show. The fan buttons, energy mode,
                  CPU power, clocks and throttling won't work.
                </p>
              </div>
              <div className="option">
                <h4>A rule just for Fanbar</h4>
                <p>
                  Run <code>sudo visudo -f /etc/sudoers.d/fanbar</code> and add this one line. It lets admin accounts run
                  only these commands without a password.
                </p>
                <Code>{SUDOERS}</Code>
                <p>
                  Then make the app owned by root, so nothing that runs as you can swap the binary and borrow that rule:
                </p>
                <Code>sudo chown -R root:wheel /Applications/Fanbar.app</Code>
                <p>To update later, remove the app with sudo, build again, then run the chown again.</p>
              </div>
              <div className="option">
                <h4>Passwordless sudo</h4>
                <p>
                  If your account already runs sudo without a password, Fanbar works as soon as it's built. Don't turn
                  that on just for this.
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="wrap foot">
        <span>Fanbar. The source is open; read it on GitHub.</span>
        <a className="link" href={REPO}>github.com/hkay-dev/fanbar</a>
      </footer>
    </>
  );
}
