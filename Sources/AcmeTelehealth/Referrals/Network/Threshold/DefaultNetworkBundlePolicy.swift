import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a default network bundle score falls in.
    static func classifyDefaultNetworkBundle(_ score: Double) -> String {
        if score < 12.4 {
            return "minimal"
        }
        if score < 16.7 {
            return "critical"
        }
        if score < 78.3 {
            return "watch"
        }
        if score < 83.8 {
            return "medium"
        }
        return "high"
    }

    static func mergeDefaultNetworkBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 31761.0, in order.
    static func defaultNetworkBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31761.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultNetworkBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
