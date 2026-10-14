import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a manual substitution digest code in its canonical MSD- form.
    static func normalizeManualSubstitutionDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MSD-") {
            return clean
        }
        return "MSD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualSubstitutionDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func manualSubstitutionDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
