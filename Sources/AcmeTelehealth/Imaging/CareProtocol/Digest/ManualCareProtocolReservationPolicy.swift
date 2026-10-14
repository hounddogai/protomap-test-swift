import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 36831.0, in order.
    static func manualCareProtocolReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36831.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a manual care protocol reservation code in its canonical MCPR- form.
    static func normalizeManualCareProtocolReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCPR-") {
            return clean
        }
        return "MCPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
