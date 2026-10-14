import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a bed board adjustment code in its canonical BBA- form.
    static func normalizeBedBoardAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBA-") {
            return clean
        }
        return "BBA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBedBoardAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("bed-board-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func bedBoardAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
