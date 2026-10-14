import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func handoffBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a handoff bundle code in its canonical HB- form.
    static func normalizeHandoffBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HB-") {
            return clean
        }
        return "HB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
