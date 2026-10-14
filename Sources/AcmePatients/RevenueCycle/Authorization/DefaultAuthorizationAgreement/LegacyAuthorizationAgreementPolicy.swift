import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeLegacyAuthorizationAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a legacy authorization agreement score falls in.
    static func classifyLegacyAuthorizationAgreement(_ score: Double) -> String {
        if score < 60.5 {
            return "critical"
        }
        if score < 70.8 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 26651.0, in order.
    static func legacyAuthorizationAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26651.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyAuthorizationAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
