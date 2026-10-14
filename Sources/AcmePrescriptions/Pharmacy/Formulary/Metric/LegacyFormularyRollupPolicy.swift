import AcmePlatform
import Foundation

extension Pharmacy {
    static func legacyFormularyRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyFormularyRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-formulary-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
