import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyRevocationManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-revocation-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyRevocationManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
