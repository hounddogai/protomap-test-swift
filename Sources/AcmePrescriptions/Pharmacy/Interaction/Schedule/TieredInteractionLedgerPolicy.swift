import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeTieredInteractionLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredInteractionLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-interaction-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered interaction ledger score falls in.
    static func classifyTieredInteractionLedger(_ score: Double) -> String {
        if score < 62.0 {
            return "minimal"
        }
        if score < 98.6 {
            return "critical"
        }
        return "ok"
    }
}
