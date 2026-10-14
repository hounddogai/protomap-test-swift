import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a program audit code in its canonical PA- form.
    static func normalizeProgramAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PA-") {
            return clean
        }
        return "PA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a program audit score falls in.
    static func classifyProgramAudit(_ score: Double) -> String {
        if score < 8.1 {
            return "elevated"
        }
        if score < 18.7 {
            return "ok"
        }
        return "critical"
    }

    static func mergeProgramAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
