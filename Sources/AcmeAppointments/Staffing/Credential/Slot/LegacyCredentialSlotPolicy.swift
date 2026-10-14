import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a legacy credential slot code in its canonical LCS- form.
    static func normalizeLegacyCredentialSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCS-") {
            return clean
        }
        return "LCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 77963.0, in order.
    static func legacyCredentialSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77963.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyCredentialSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-credential-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
