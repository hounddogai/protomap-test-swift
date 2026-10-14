import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualBedBoardWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-bed-board-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeManualBedBoardWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a manual bed board window code in its canonical MBBW- form.
    static func normalizeManualBedBoardWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MBBW-") {
            return clean
        }
        return "MBBW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
