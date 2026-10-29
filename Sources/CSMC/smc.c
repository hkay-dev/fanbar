#include "smc.h"
#include <IOKit/IOKitLib.h>
#include <string.h>

typedef struct { char major, minor, build, reserved[1]; uint16_t release; } SMCVers;
typedef struct { uint16_t version, length; uint32_t cpuPLimit, gpuPLimit, memPLimit; } SMCPLimit;
typedef struct { uint32_t dataSize, dataType; char dataAttributes; } SMCKeyInfo;
typedef struct {
    uint32_t key; SMCVers vers; SMCPLimit pLimitData; SMCKeyInfo keyInfo;
    char result, status, data8; uint32_t data32; uint8_t bytes[32];
} SMCKeyData;

static io_connect_t conn;

static uint32_t k2u(const char *s) { return (uint32_t)s[0] << 24 | (uint32_t)s[1] << 16 | (uint32_t)s[2] << 8 | (uint32_t)s[3]; }
static void u2k(uint32_t v, char *s) { s[0] = v >> 24; s[1] = v >> 16; s[2] = v >> 8; s[3] = v; s[4] = 0; }

static int call(SMCKeyData *in, SMCKeyData *out) {
    if (!conn) {
        io_service_t svc = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
        if (!svc || IOServiceOpen(svc, mach_task_self(), 0, &conn)) return -1;
    }
    size_t size = sizeof(SMCKeyData);
    kern_return_t r = IOConnectCallStructMethod(conn, 2, in, sizeof(SMCKeyData), out, &size);
    return r == KERN_SUCCESS && out->result == 0 ? 0 : -1;
}

// A key's size and type never change, so each is asked once. Fanbar reads a few hundred keys at most; the table stays
// half empty so the probe always ends.
static struct { uint32_t key; SMCKeyInfo info; } known[1024];
static int knownCount;

static int info(uint32_t key, SMCKeyInfo *ki) {
    uint32_t i = key % 1024;
    while (known[i].key && known[i].key != key) i = (i + 1) % 1024;
    if (known[i].key) { *ki = known[i].info; return 0; }
    SMCKeyData in = {0}, out = {0};
    in.key = key; in.data8 = 9;
    if (call(&in, &out)) return -1;
    *ki = out.keyInfo;
    if (knownCount < 512) { known[i].key = key; known[i].info = *ki; knownCount++; }
    return 0;
}

int smc_read(const char *key, char type[5], uint8_t bytes[32]) {
    SMCKeyInfo ki;
    if (strlen(key) != 4 || info(k2u(key), &ki)) return -1;
    SMCKeyData in = {0}, out = {0};
    in.key = k2u(key); in.keyInfo.dataSize = ki.dataSize; in.data8 = 5;
    if (call(&in, &out)) return -1;
    u2k(ki.dataType, type);
    memcpy(bytes, out.bytes, 32);
    return 0;
}

int smc_write(const char *key, const uint8_t *bytes, uint32_t size) {
    SMCKeyInfo ki;
    if (strlen(key) != 4 || info(k2u(key), &ki) || ki.dataSize != size || size > 32) return -1;
    SMCKeyData in = {0}, out = {0};
    in.key = k2u(key); in.keyInfo.dataSize = size; in.data8 = 6;
    memcpy(in.bytes, bytes, size);
    return call(&in, &out);
}

uint32_t smc_count(void) {
    char type[5]; uint8_t b[32];
    if (smc_read("#KEY", type, b)) return 0;
    return (uint32_t)b[0] << 24 | (uint32_t)b[1] << 16 | (uint32_t)b[2] << 8 | b[3];
}

int smc_key_at(uint32_t index, char key[5]) {
    SMCKeyData in = {0}, out = {0};
    in.data8 = 8; in.data32 = index;
    if (call(&in, &out)) return -1;
    u2k(out.key, key);
    return 0;
}
