import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackOutreachAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-outreach-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeFallbackOutreachAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a fallback outreach audit code in its canonical FOA- form.
    static func normalizeFallbackOutreachAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FOA-") {
            return clean
        }
        return "FOA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
