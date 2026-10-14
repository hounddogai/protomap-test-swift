import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a lenient worklist exception code in its canonical LWE- form.
    static func normalizeLenientWorklistExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LWE-") {
            return clean
        }
        return "LWE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a lenient worklist exception score falls in.
    static func classifyLenientWorklistException(_ score: Double) -> String {
        if score < 2.5 {
            return "critical"
        }
        if score < 78.5 {
            return "watch"
        }
        if score < 81.6 {
            return "medium"
        }
        return "high"
    }
}
