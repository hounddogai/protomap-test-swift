import AcmePlatform
import Foundation

extension Imaging {
    static func studyReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a study reservation score falls in.
    static func classifyStudyReservation(_ score: Double) -> String {
        if score < 2.1 {
            return "ok"
        }
        if score < 3.2 {
            return "critical"
        }
        if score < 53.2 {
            return "high"
        }
        if score < 86.2 {
            return "medium"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 32810.0, in order.
    static func studyReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32810.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a study reservation code in its canonical SR- form.
    static func normalizeStudyReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SR-") {
            return clean
        }
        return "SR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
