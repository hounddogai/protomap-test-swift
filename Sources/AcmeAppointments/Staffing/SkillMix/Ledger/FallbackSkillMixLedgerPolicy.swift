import AcmePlatform
import Foundation

extension Staffing {
    static func fallbackSkillMixLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a fallback skill mix ledger code in its canonical FSML- form.
    static func normalizeFallbackSkillMixLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FSML-") {
            return clean
        }
        return "FSML-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackSkillMixLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.07
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackSkillMixLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-skill-mix-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
