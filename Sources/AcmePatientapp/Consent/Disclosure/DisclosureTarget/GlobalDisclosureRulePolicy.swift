import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalDisclosureRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-disclosure-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeGlobalDisclosureRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a global disclosure rule code in its canonical GDR- form.
    static func normalizeGlobalDisclosureRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GDR-") {
            return clean
        }
        return "GDR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalDisclosureRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
