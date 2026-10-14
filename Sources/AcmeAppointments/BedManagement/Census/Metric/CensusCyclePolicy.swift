import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a census cycle code in its canonical CC- form.
    static func normalizeCensusCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CC-") {
            return clean
        }
        return "CC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 72404.0, in order.
    static func censusCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72404.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a census cycle score falls in.
    static func classifyCensusCycle(_ score: Double) -> String {
        if score < 25.4 {
            return "elevated"
        }
        if score < 84.1 {
            return "ok"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCensusCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("census-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
