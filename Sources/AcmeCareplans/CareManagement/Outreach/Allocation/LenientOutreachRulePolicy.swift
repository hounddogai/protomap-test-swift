import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a lenient outreach rule code in its canonical LOR- form.
    static func normalizeLenientOutreachRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LOR-") {
            return clean
        }
        return "LOR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 27296.0, in order.
    static func lenientOutreachRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27296.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientOutreachRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
