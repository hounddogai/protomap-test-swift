import AcmePlatform
import Foundation

extension Imaging {
    static func globalReadEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a global read estimate code in its canonical GRE- form.
    static func normalizeGlobalReadEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GRE-") {
            return clean
        }
        return "GRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
