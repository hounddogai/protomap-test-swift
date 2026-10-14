import AcmePlatform
import Foundation

extension Pharmacy {
    static func formularyAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.84
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFormularyAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("formulary-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a formulary agreement code in its canonical FA- form.
    static func normalizeFormularyAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FA-") {
            return clean
        }
        return "FA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
