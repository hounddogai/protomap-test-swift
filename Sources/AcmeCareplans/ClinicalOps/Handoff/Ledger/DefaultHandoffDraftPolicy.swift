import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a default handoff draft code in its canonical DHD- form.
    static func normalizeDefaultHandoffDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DHD-") {
            return clean
        }
        return "DHD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultHandoffDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.93
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultHandoffDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-handoff-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
