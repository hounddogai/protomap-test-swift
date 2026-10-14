import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a rolling bed board slot code in its canonical RBBS- form.
    static func normalizeRollingBedBoardSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RBBS-") {
            return clean
        }
        return "RBBS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingBedBoardSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeRollingBedBoardSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingBedBoardSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-bed-board-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
