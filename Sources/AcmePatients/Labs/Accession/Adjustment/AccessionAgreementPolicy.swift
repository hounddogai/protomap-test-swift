import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAccessionAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("accession-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 89943.0, in order.
    static func accessionAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89943.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a accession agreement score falls in.
    static func classifyAccessionAgreement(_ score: Double) -> String {
        if score < 4.8 {
            return "elevated"
        }
        if score < 50.2 {
            return "critical"
        }
        if score < 58.8 {
            return "ok"
        }
        if score < 88.9 {
            return "minimal"
        }
        return "medium"
    }

    /// Puts a accession agreement code in its canonical AA- form.
    static func normalizeAccessionAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AA-") {
            return clean
        }
        return "AA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
