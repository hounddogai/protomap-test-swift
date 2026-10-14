import AcmePlatform
import Foundation

extension Staffing {
    static func primaryAcuityPlanTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryAcuityPlanTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-acuity-plan-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a primary acuity plan target code in its canonical PAPT- form.
    static func normalizePrimaryAcuityPlanTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAPT-") {
            return clean
        }
        return "PAPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryAcuityPlanTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
