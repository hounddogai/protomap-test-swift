import AcmePlatform
import Foundation

extension ClinicalOps {
    static func cappedCareProtocolQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func cappedCareProtocolQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedCareProtocolQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-care-protocol-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a capped care protocol quota code in its canonical CCPQ- form.
    static func normalizeCappedCareProtocolQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCPQ-") {
            return clean
        }
        return "CCPQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
