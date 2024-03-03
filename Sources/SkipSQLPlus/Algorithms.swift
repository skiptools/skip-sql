// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
import SkipFFI
#if !SKIP
import SQLExt
#endif

internal final class AlgorithmsLibrary {
    static let shared = registerNatives(AlgorithmsLibrary(), frameworkName: "SkipSQLPlus", libraryName: "sqlext")

    // MARK: Self-test functions

    /* SKIP EXTERN */ public func safer_k64_test() -> Int32 { SQLExt.safer_k64_test() }
    /* SKIP EXTERN */ public func safer_sk64_test() -> Int32 { SQLExt.safer_sk64_test() }
    /* SKIP EXTERN */ public func safer_sk128_test() -> Int32 { SQLExt.safer_sk128_test() }
    /* SKIP EXTERN */ public func saferp_test() -> Int32 { SQLExt.saferp_test() }
    /* SKIP EXTERN */ public func twofish_test() -> Int32 { SQLExt.twofish_test() }
    /* SKIP EXTERN */ public func anubis_test() -> Int32 { SQLExt.anubis_test() }
    /* SKIP EXTERN */ public func blowfish_test() -> Int32 { SQLExt.blowfish_test() }
    /* SKIP EXTERN */ public func camellia_test() -> Int32 { SQLExt.camellia_test() }
    /* SKIP EXTERN */ public func cast5_test() -> Int32 { SQLExt.cast5_test() }
    /* SKIP EXTERN */ public func des_test() -> Int32 { SQLExt.des_test() }
    /* SKIP EXTERN */ public func des3_test() -> Int32 { SQLExt.des3_test() }
    /* SKIP EXTERN */ public func idea_test() -> Int32 { SQLExt.idea_test() }
    /* SKIP EXTERN */ public func kasumi_test() -> Int32 { SQLExt.kasumi_test() }
    /* SKIP EXTERN */ public func khazad_test() -> Int32 { SQLExt.khazad_test() }
    /* SKIP EXTERN */ public func kseed_test() -> Int32 { SQLExt.kseed_test() }
    /* SKIP EXTERN */ public func multi2_test() -> Int32 { SQLExt.multi2_test() }
    /* SKIP EXTERN */ public func noekeon_test() -> Int32 { SQLExt.noekeon_test() }
    /* SKIP EXTERN */ public func rc2_test() -> Int32 { SQLExt.rc2_test() }
    /* SKIP EXTERN */ public func rc5_test() -> Int32 { SQLExt.rc5_test() }
    /* SKIP EXTERN */ public func rc6_test() -> Int32 { SQLExt.rc6_test() }
    /* SKIP EXTERN */ public func serpent_test() -> Int32 { SQLExt.serpent_test() }
    /* SKIP EXTERN */ public func skipjack_test() -> Int32 { SQLExt.skipjack_test() }
    /* SKIP EXTERN */ public func tea_test() -> Int32 { SQLExt.tea_test() }
    /* SKIP EXTERN */ public func xtea_test() -> Int32 { SQLExt.xtea_test() }
    /* SKIP EXTERN */ public func ccm_test() -> Int32 { SQLExt.ccm_test() }
    /* SKIP EXTERN */ public func chacha20poly1305_test() -> Int32 { SQLExt.chacha20poly1305_test() }
    /* SKIP EXTERN */ public func eax_test() -> Int32 { SQLExt.eax_test() }
    /* SKIP EXTERN */ public func gcm_test() -> Int32 { SQLExt.gcm_test() }
    /* SKIP EXTERN */ public func ocb_test() -> Int32 { SQLExt.ocb_test() }
    /* SKIP EXTERN */ public func ocb3_test() -> Int32 { SQLExt.ocb3_test() }
    /* SKIP EXTERN */ public func chc_test() -> Int32 { SQLExt.chc_test() }
    /* SKIP EXTERN */ public func sha224_test() -> Int32 { SQLExt.sha224_test() }
    /* SKIP EXTERN */ public func sha256_test() -> Int32 { SQLExt.sha256_test() }
    /* SKIP EXTERN */ public func sha384_test() -> Int32 { SQLExt.sha384_test() }
    /* SKIP EXTERN */ public func sha512_224_test() -> Int32 { SQLExt.sha512_224_test() }
    /* SKIP EXTERN */ public func sha512_256_test() -> Int32 { SQLExt.sha512_256_test() }
    /* SKIP EXTERN */ public func sha512_test() -> Int32 { SQLExt.sha512_test() }
    /* SKIP EXTERN */ public func whirlpool_test() -> Int32 { SQLExt.whirlpool_test() }
    /* SKIP EXTERN */ public func blake2b_512_test() -> Int32 { SQLExt.blake2b_512_test() }
    /* SKIP EXTERN */ public func blake2b_384_test() -> Int32 { SQLExt.blake2b_384_test() }
    /* SKIP EXTERN */ public func blake2b_256_test() -> Int32 { SQLExt.blake2b_256_test() }
    /* SKIP EXTERN */ public func blake2b_160_test() -> Int32 { SQLExt.blake2b_160_test() }
    /* SKIP EXTERN */ public func blake2s_256_test() -> Int32 { SQLExt.blake2s_256_test() }
    /* SKIP EXTERN */ public func blake2s_224_test() -> Int32 { SQLExt.blake2s_224_test() }
    /* SKIP EXTERN */ public func blake2s_160_test() -> Int32 { SQLExt.blake2s_160_test() }
    /* SKIP EXTERN */ public func blake2s_128_test() -> Int32 { SQLExt.blake2s_128_test() }
    /* SKIP EXTERN */ public func md2_test() -> Int32 { SQLExt.md2_test() }
    /* SKIP EXTERN */ public func md4_test() -> Int32 { SQLExt.md4_test() }
    /* SKIP EXTERN */ public func md5_test() -> Int32 { SQLExt.md5_test() }
    /* SKIP EXTERN */ public func rmd128_test() -> Int32 { SQLExt.rmd128_test() }
    /* SKIP EXTERN */ public func rmd160_test() -> Int32 { SQLExt.rmd160_test() }
    /* SKIP EXTERN */ public func rmd256_test() -> Int32 { SQLExt.rmd256_test() }
    /* SKIP EXTERN */ public func rmd320_test() -> Int32 { SQLExt.rmd320_test() }
    /* SKIP EXTERN */ public func sha1_test() -> Int32 { SQLExt.sha1_test() }
    /* SKIP EXTERN */ public func sha3_224_test() -> Int32 { SQLExt.sha3_224_test() }
    /* SKIP EXTERN */ public func sha3_256_test() -> Int32 { SQLExt.sha3_256_test() }
    /* SKIP EXTERN */ public func sha3_384_test() -> Int32 { SQLExt.sha3_384_test() }
    /* SKIP EXTERN */ public func sha3_512_test() -> Int32 { SQLExt.sha3_512_test() }
    /* SKIP EXTERN */ public func sha3_shake_test() -> Int32 { SQLExt.sha3_shake_test() }
    /* SKIP EXTERN */ public func keccak_224_test() -> Int32 { SQLExt.keccak_224_test() }
    /* SKIP EXTERN */ public func keccak_256_test() -> Int32 { SQLExt.keccak_256_test() }
    /* SKIP EXTERN */ public func keccak_384_test() -> Int32 { SQLExt.keccak_384_test() }
    /* SKIP EXTERN */ public func keccak_512_test() -> Int32 { SQLExt.keccak_512_test() }
    /* SKIP EXTERN */ public func tiger_test() -> Int32 { SQLExt.tiger_test() }
    /* SKIP EXTERN */ public func blake2bmac_test() -> Int32 { SQLExt.blake2bmac_test() }
    /* SKIP EXTERN */ public func blake2smac_test() -> Int32 { SQLExt.blake2smac_test() }
    /* SKIP EXTERN */ public func f9_test() -> Int32 { SQLExt.f9_test() }
    /* SKIP EXTERN */ public func hmac_test() -> Int32 { SQLExt.hmac_test() }
    /* SKIP EXTERN */ public func omac_test() -> Int32 { SQLExt.omac_test() }
    /* SKIP EXTERN */ public func pelican_test() -> Int32 { SQLExt.pelican_test() }
    /* SKIP EXTERN */ public func pmac_test() -> Int32 { SQLExt.pmac_test() }
    /* SKIP EXTERN */ public func poly1305_test() -> Int32 { SQLExt.poly1305_test() }
    /* SKIP EXTERN */ public func xcbc_test() -> Int32 { SQLExt.xcbc_test() }
    /* SKIP EXTERN */ public func hkdf_test() -> Int32 { SQLExt.hkdf_test() }
    /* SKIP EXTERN */ public func adler32_test() -> Int32 { SQLExt.adler32_test() }
    /* SKIP EXTERN */ public func crc32_test() -> Int32 { SQLExt.crc32_test() }
    /* SKIP EXTERN */ public func ctr_test() -> Int32 { SQLExt.ctr_test() }
    /* SKIP EXTERN */ public func lrw_test() -> Int32 { SQLExt.lrw_test() }
    /* SKIP EXTERN */ public func xts_test() -> Int32 { SQLExt.xts_test() }
    /* SKIP EXTERN */ public func chacha20_prng_test() -> Int32 { SQLExt.chacha20_prng_test() }
    /* SKIP EXTERN */ public func fortuna_test() -> Int32 { SQLExt.fortuna_test() }
    /* SKIP EXTERN */ public func rc4_test() -> Int32 { SQLExt.rc4_test() }
    /* SKIP EXTERN */ public func sober128_test() -> Int32 { SQLExt.sober128_test() }
    /* SKIP EXTERN */ public func sprng_test() -> Int32 { SQLExt.sprng_test() }
    /* SKIP EXTERN */ public func yarrow_test() -> Int32 { SQLExt.yarrow_test() }
    /* SKIP EXTERN */ public func chacha_test() -> Int32 { SQLExt.chacha_test() }
    /* SKIP EXTERN */ public func rabbit_test() -> Int32 { SQLExt.rabbit_test() }
    /* SKIP EXTERN */ public func rc4_stream_test() -> Int32 { SQLExt.rc4_stream_test() }
    /* SKIP EXTERN */ public func salsa20_test() -> Int32 { SQLExt.salsa20_test() }
    /* SKIP EXTERN */ public func xsalsa20_test() -> Int32 { SQLExt.xsalsa20_test() }
    /* SKIP EXTERN */ public func sober128_stream_test() -> Int32 { SQLExt.sober128_stream_test() }
    /* SKIP EXTERN */ public func sosemanuk_test() -> Int32 { SQLExt.sosemanuk_test() }

}
