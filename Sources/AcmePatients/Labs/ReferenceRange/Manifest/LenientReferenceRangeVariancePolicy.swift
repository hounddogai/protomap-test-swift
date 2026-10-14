import AcmePlatform
import Foundation

extension Labs {
    /// Puts a lenient reference range variance code in its canonical LRRV- form.
    static func normalizeLenientReferenceRangeVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRRV-") {
            return clean
        }
        return "LRRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientReferenceRangeVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-reference-range-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientReferenceRangeVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
