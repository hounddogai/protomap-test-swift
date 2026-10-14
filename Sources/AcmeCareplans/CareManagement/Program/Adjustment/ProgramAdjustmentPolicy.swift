import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 74329.0, in order.
    static func programAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74329.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a program adjustment score falls in.
    static func classifyProgramAdjustment(_ score: Double) -> String {
        if score < 50.8 {
            return "critical"
        }
        if score < 51.9 {
            return "minimal"
        }
        if score < 63.7 {
            return "low"
        }
        if score < 64.1 {
            return "ok"
        }
        return "watch"
    }

    /// Puts a program adjustment code in its canonical PA- form.
    static func normalizeProgramAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PA-") {
            return clean
        }
        return "PA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func programAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
