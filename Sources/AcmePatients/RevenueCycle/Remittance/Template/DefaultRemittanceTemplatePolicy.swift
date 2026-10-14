import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a default remittance template score falls in.
    static func classifyDefaultRemittanceTemplate(_ score: Double) -> String {
        if score < 38.4 {
            return "high"
        }
        if score < 75.9 {
            return "ok"
        }
        return "critical"
    }

    /// Puts a default remittance template code in its canonical DRT- form.
    static func normalizeDefaultRemittanceTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRT-") {
            return clean
        }
        return "DRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultRemittanceTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func defaultRemittanceTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
