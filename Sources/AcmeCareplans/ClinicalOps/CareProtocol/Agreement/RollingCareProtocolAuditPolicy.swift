import AcmePlatform
import Foundation

extension ClinicalOps {
    static func rollingCareProtocolAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingCareProtocolAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-care-protocol-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling care protocol audit code in its canonical RCPA- form.
    static func normalizeRollingCareProtocolAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCPA-") {
            return clean
        }
        return "RCPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
