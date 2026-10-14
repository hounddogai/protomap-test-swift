import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a pending program target score falls in.
    static func classifyPendingProgramTarget(_ score: Double) -> String {
        if score < 52.7 {
            return "medium"
        }
        if score < 57.2 {
            return "low"
        }
        if score < 72.5 {
            return "ok"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingProgramTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-program-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a pending program target code in its canonical PPT- form.
    static func normalizePendingProgramTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPT-") {
            return clean
        }
        return "PPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 14157.0, in order.
    static func pendingProgramTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14157.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
