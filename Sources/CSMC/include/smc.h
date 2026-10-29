#include <stdint.h>

// Read a key: fills its 4-char type (plus NUL) and up to 32 raw bytes. Returns 0 on success.
int smc_read(const char *key, char type[5], uint8_t bytes[32]);
// Write raw bytes to a key (needs root). Returns 0 on success.
int smc_write(const char *key, const uint8_t *bytes, uint32_t size);
// Key enumeration.
uint32_t smc_count(void);
int smc_key_at(uint32_t index, char key[5]);
