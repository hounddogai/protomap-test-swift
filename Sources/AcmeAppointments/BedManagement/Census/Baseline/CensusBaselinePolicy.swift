import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCensusBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("census-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a census baseline score falls in.
    static func classifyCensusBaseline(_ score: Double) -> String {
        if score < 8.0 {
            return "watch"
        }
        if score < 41.7 {
            return "elevated"
        }
        if score < 75.1 {
            return "high"
        }
        if score < 99.6 {
            return "ok"
        }
        return "minimal"
    }
}
