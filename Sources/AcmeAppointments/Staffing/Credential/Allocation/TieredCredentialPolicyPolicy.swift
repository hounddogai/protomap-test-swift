import AcmePlatform
import Foundation

extension Staffing {
    static func mergeTieredCredentialPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredCredentialPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-credential-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func tieredCredentialPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a tiered credential policy code in its canonical TCP- form.
    static func normalizeTieredCredentialPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCP-") {
            return clean
        }
        return "TCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
