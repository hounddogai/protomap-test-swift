import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a adaptive handoff ledger code in its canonical AHL- form.
    static func normalizeAdaptiveHandoffLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AHL-") {
            return clean
        }
        return "AHL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveHandoffLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func adaptiveHandoffLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveHandoffLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-handoff-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
