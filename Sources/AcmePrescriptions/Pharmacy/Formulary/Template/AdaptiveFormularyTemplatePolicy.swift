import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a adaptive formulary template code in its canonical AFT- form.
    static func normalizeAdaptiveFormularyTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AFT-") {
            return clean
        }
        return "AFT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveFormularyTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveFormularyTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-formulary-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 55782.0, in order.
    static func adaptiveFormularyTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 55782.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
