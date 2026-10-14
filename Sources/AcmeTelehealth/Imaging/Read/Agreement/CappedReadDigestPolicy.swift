import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedReadDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-read-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a capped read digest code in its canonical CRD- form.
    static func normalizeCappedReadDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRD-") {
            return clean
        }
        return "CRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped read digest score falls in.
    static func classifyCappedReadDigest(_ score: Double) -> String {
        if score < 9.9 {
            return "low"
        }
        if score < 95.3 {
            return "medium"
        }
        return "critical"
    }
}
