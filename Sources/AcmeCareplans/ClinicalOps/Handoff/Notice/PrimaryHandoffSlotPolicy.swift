import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryHandoffSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-handoff-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a primary handoff slot code in its canonical PHS- form.
    static func normalizePrimaryHandoffSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PHS-") {
            return clean
        }
        return "PHS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
