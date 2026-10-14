import AcmePlatform
import Foundation

extension CareManagement {
    static func strictAssessmentReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeStrictAssessmentReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictAssessmentReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-assessment-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a strict assessment reservation code in its canonical SAR- form.
    static func normalizeStrictAssessmentReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAR-") {
            return clean
        }
        return "SAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
