import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a default interaction agreement code in its canonical DIA- form.
    static func normalizeDefaultInteractionAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DIA-") {
            return clean
        }
        return "DIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultInteractionAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a default interaction agreement score falls in.
    static func classifyDefaultInteractionAgreement(_ score: Double) -> String {
        if score < 27.4 {
            return "ok"
        }
        if score < 75.1 {
            return "critical"
        }
        if score < 88.3 {
            return "medium"
        }
        return "watch"
    }
}
