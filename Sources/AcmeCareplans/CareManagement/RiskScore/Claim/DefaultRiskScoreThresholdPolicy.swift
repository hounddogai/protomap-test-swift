import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultRiskScoreThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-risk-score-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a default risk score threshold code in its canonical DRST- form.
    static func normalizeDefaultRiskScoreThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRST-") {
            return clean
        }
        return "DRST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 10768.0, in order.
    static func defaultRiskScoreThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10768.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeDefaultRiskScoreThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
