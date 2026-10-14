import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a manual transfer template code in its canonical MTT- form.
    static func normalizeManualTransferTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MTT-") {
            return clean
        }
        return "MTT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualTransferTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualTransferTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-transfer-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
