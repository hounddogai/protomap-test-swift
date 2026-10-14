import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a lenient specimen reservation score falls in.
    static func classifyLenientSpecimenReservation(_ score: Double) -> String {
        if score < 17.0 {
            return "medium"
        }
        if score < 42.9 {
            return "minimal"
        }
        if score < 73.3 {
            return "critical"
        }
        if score < 99.6 {
            return "ok"
        }
        return "low"
    }

    static func lenientSpecimenReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a lenient specimen reservation code in its canonical LSR- form.
    static func normalizeLenientSpecimenReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LSR-") {
            return clean
        }
        return "LSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 9185.0, in order.
    static func lenientSpecimenReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9185.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
