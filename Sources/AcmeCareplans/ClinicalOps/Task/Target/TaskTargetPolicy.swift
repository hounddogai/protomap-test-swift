import AcmePlatform
import Foundation

extension ClinicalOps {
    static func taskTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func taskTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a task target code in its canonical TT- form.
    static func normalizeTaskTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TT-") {
            return clean
        }
        return "TT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
