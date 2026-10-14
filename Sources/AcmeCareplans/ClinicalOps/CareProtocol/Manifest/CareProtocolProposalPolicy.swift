import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol proposal code in its canonical CPP- form.
    static func normalizeCareProtocolProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPP-") {
            return clean
        }
        return "CPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 97157.0, in order.
    static func careProtocolProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97157.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func careProtocolProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
