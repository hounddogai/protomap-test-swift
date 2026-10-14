import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeDischargePlanSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a discharge plan segment code in its canonical DPS- form.
    static func normalizeDischargePlanSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPS-") {
            return clean
        }
        return "DPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
