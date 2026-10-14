import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a transfer checkpoint code in its canonical TC- form.
    static func normalizeTransferCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TC-") {
            return clean
        }
        return "TC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func transferCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func transferCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
