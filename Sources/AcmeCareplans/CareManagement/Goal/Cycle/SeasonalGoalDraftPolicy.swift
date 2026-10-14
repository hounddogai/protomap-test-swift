import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalGoalDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-goal-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalGoalDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a seasonal goal draft code in its canonical SGD- form.
    static func normalizeSeasonalGoalDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SGD-") {
            return clean
        }
        return "SGD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
