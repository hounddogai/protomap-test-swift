import AcmePlatform
import Foundation

extension Consent {
    static func mergeRevocationEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a revocation estimate code in its canonical RE- form.
    static func normalizeRevocationEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RE-") {
            return clean
        }
        return "RE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
