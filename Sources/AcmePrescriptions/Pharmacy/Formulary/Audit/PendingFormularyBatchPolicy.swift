import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingFormularyBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-formulary-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a pending formulary batch score falls in.
    static func classifyPendingFormularyBatch(_ score: Double) -> String {
        if score < 43.1 {
            return "ok"
        }
        if score < 56.6 {
            return "low"
        }
        return "watch"
    }

    /// Puts a pending formulary batch code in its canonical PFB- form.
    static func normalizePendingFormularyBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PFB-") {
            return clean
        }
        return "PFB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
