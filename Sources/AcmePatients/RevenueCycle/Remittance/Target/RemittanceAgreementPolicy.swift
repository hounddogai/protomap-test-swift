import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a remittance agreement code in its canonical RA- form.
    static func normalizeRemittanceAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RA-") {
            return clean
        }
        return "RA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 79350.0, in order.
    static func remittanceAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79350.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
