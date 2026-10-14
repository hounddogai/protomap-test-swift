import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a care gap mapping code in its canonical CGM- form.
    static func normalizeCareGapMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGM-") {
            return clean
        }
        return "CGM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a care gap mapping score falls in.
    static func classifyCareGapMapping(_ score: Double) -> String {
        if score < 6.1 {
            return "low"
        }
        if score < 25.7 {
            return "medium"
        }
        if score < 82.2 {
            return "watch"
        }
        if score < 90.3 {
            return "minimal"
        }
        return "ok"
    }
}
