import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a primary cleaning manifest score falls in.
    static func classifyPrimaryCleaningManifest(_ score: Double) -> String {
        if score < 23.4 {
            return "low"
        }
        if score < 76.9 {
            return "minimal"
        }
        if score < 90.1 {
            return "high"
        }
        return "medium"
    }

    static func primaryCleaningManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryCleaningManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-cleaning-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 64936.0, in order.
    static func primaryCleaningManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64936.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
