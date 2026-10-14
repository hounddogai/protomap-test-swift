import AcmePlatform
import Foundation

extension Pharmacy {
    static func tieredFormularyTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a tiered formulary template code in its canonical TFT- form.
    static func normalizeTieredFormularyTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TFT-") {
            return clean
        }
        return "TFT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
