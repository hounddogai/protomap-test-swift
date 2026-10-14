import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedOrderSetPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-order-set-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedOrderSetPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a batched order set preference code in its canonical BOSP- form.
    static func normalizeBatchedOrderSetPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BOSP-") {
            return clean
        }
        return "BOSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
