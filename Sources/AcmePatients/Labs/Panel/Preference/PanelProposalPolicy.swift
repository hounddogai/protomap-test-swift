import AcmePlatform
import Foundation

extension Labs {
    static func mergePanelProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 29250.0, in order.
    static func panelProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29250.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a panel proposal code in its canonical PP- form.
    static func normalizePanelProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PP-") {
            return clean
        }
        return "PP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a panel proposal score falls in.
    static func classifyPanelProposal(_ score: Double) -> String {
        if score < 6.7 {
            return "elevated"
        }
        if score < 59.0 {
            return "minimal"
        }
        return "ok"
    }
}
