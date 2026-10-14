import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a census proposal code in its canonical CP- form.
    static func normalizeCensusProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CP-") {
            return clean
        }
        return "CP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a census proposal score falls in.
    static func classifyCensusProposal(_ score: Double) -> String {
        if score < 16.1 {
            return "low"
        }
        if score < 23.6 {
            return "ok"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 40173.0, in order.
    static func censusProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40173.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
