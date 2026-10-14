import AcmePlatform
import Foundation

extension BedManagement {
    static func legacyCensusEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a legacy census entry code in its canonical LCE- form.
    static func normalizeLegacyCensusEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCE-") {
            return clean
        }
        return "LCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyCensusEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyCensusEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-census-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
