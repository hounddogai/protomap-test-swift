import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a legacy task schedule code in its canonical LTS- form.
    static func normalizeLegacyTaskScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LTS-") {
            return clean
        }
        return "LTS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyTaskScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
