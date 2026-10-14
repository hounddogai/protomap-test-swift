import AcmePlatform
import Foundation

extension Labs {
    /// Puts a accession budget code in its canonical AB- form.
    static func normalizeAccessionBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AB-") {
            return clean
        }
        return "AB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAccessionBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("accession-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
