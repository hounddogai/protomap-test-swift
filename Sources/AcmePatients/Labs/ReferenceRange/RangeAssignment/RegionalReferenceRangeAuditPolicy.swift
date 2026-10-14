import AcmePlatform
import Foundation

extension Labs {
    static func regionalReferenceRangeAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalReferenceRangeAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-reference-range-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a regional reference range audit code in its canonical RRRA- form.
    static func normalizeRegionalReferenceRangeAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRRA-") {
            return clean
        }
        return "RRRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
