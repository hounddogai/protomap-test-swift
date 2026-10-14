import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a capped remittance template code in its canonical CRT- form.
    static func normalizeCappedRemittanceTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRT-") {
            return clean
        }
        return "CRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedRemittanceTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedRemittanceTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-remittance-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 57888.0, in order.
    static func cappedRemittanceTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57888.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
