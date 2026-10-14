import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedCensusBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-census-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a capped census baseline score falls in.
    static func classifyCappedCensusBaseline(_ score: Double) -> String {
        if score < 24.4 {
            return "watch"
        }
        if score < 49.7 {
            return "elevated"
        }
        if score < 86.1 {
            return "critical"
        }
        return "low"
    }
}
