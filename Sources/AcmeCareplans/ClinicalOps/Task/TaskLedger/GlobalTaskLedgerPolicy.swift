import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a global task ledger code in its canonical GTL- form.
    static func normalizeGlobalTaskLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GTL-") {
            return clean
        }
        return "GTL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalTaskLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeGlobalTaskLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalTaskLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-task-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
