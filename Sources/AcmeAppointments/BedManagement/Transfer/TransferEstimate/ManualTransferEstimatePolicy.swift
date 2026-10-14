import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a manual transfer estimate score falls in.
    static func classifyManualTransferEstimate(_ score: Double) -> String {
        if score < 15.3 {
            return "watch"
        }
        if score < 72.6 {
            return "low"
        }
        if score < 95.5 {
            return "high"
        }
        if score < 99.3 {
            return "minimal"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualTransferEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-transfer-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a manual transfer estimate code in its canonical MTE- form.
    static func normalizeManualTransferEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MTE-") {
            return clean
        }
        return "MTE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
