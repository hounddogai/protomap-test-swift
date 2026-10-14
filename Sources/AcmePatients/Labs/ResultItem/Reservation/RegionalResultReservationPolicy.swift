import AcmePlatform
import Foundation

extension Labs {
    /// Puts a regional result reservation code in its canonical RRR- form.
    static func normalizeRegionalResultReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRR-") {
            return clean
        }
        return "RRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalResultReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
