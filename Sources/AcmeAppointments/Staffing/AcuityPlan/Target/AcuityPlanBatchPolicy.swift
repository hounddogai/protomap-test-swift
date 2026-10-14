import AcmePlatform
import Foundation

extension Staffing {
    static func acuityPlanBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func acuityPlanBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a acuity plan batch code in its canonical APB- form.
    static func normalizeAcuityPlanBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APB-") {
            return clean
        }
        return "APB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
