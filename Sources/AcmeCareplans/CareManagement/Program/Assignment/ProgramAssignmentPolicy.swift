import AcmePlatform
import Foundation

extension CareManagement {
    static func programAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a program assignment code in its canonical PA- form.
    static func normalizeProgramAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PA-") {
            return clean
        }
        return "PA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
