import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a transfer rule code in its canonical TR- form.
    static func normalizeTransferRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TR-") {
            return clean
        }
        return "TR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTransferRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("transfer-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
