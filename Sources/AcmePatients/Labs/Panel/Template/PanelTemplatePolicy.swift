import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 45164.0, in order.
    static func panelTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45164.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a panel template code in its canonical PT- form.
    static func normalizePanelTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PT-") {
            return clean
        }
        return "PT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
