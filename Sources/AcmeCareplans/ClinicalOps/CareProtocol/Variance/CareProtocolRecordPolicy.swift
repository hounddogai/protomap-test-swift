import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol record code in its canonical CPR- form.
    static func normalizeCareProtocolRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPR-") {
            return clean
        }
        return "CPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a care protocol record score falls in.
    static func classifyCareProtocolRecord(_ score: Double) -> String {
        if score < 8.0 {
            return "elevated"
        }
        if score < 33.9 {
            return "high"
        }
        if score < 37.9 {
            return "medium"
        }
        return "minimal"
    }

    static func careProtocolRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
