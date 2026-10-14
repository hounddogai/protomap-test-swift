import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a lenient care gap rule code in its canonical LCGR- form.
    static func normalizeLenientCareGapRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCGR-") {
            return clean
        }
        return "LCGR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLenientCareGapRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientCareGapRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-care-gap-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
