import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a care protocol cycle code in its canonical CPC- form.
    static func normalizeCareProtocolCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPC-") {
            return clean
        }
        return "CPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careProtocolCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
