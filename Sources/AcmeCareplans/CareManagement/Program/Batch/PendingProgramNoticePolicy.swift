import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a pending program notice score falls in.
    static func classifyPendingProgramNotice(_ score: Double) -> String {
        if score < 53.8 {
            return "low"
        }
        if score < 78.8 {
            return "elevated"
        }
        return "ok"
    }

    /// Puts a pending program notice code in its canonical PPN- form.
    static func normalizePendingProgramNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPN-") {
            return clean
        }
        return "PPN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
