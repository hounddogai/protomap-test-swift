import AcmePlatform
import Foundation

extension Referrals {
    static func mergeManualNetworkWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 16010.0, in order.
    static func manualNetworkWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16010.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a manual network window code in its canonical MNW- form.
    static func normalizeManualNetworkWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MNW-") {
            return clean
        }
        return "MNW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a manual network window score falls in.
    static func classifyManualNetworkWindow(_ score: Double) -> String {
        if score < 40.7 {
            return "elevated"
        }
        if score < 73.2 {
            return "medium"
        }
        if score < 80.7 {
            return "high"
        }
        if score < 87.6 {
            return "minimal"
        }
        return "critical"
    }
}
