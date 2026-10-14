import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a order set rule code in its canonical OSR- form.
    static func normalizeOrderSetRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSR-") {
            return clean
        }
        return "OSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
