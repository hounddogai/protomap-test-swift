import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a risk score digest code in its canonical RSD- form.
    static func normalizeRiskScoreDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSD-") {
            return clean
        }
        return "RSD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRiskScoreDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("risk-score-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 75191.0, in order.
    static func riskScoreDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75191.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
