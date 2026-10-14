import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a credential adjustment score falls in.
    static func classifyCredentialAdjustment(_ score: Double) -> String {
        if score < 7.5 {
            return "medium"
        }
        if score < 12.3 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCredentialAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a credential adjustment code in its canonical CA- form.
    static func normalizeCredentialAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CA-") {
            return clean
        }
        return "CA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
