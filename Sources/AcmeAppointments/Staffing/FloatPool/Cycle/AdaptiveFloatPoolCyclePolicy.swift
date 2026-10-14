import AcmePlatform
import Foundation

extension Staffing {
    static func adaptiveFloatPoolCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a adaptive float pool cycle code in its canonical AFPC- form.
    static func normalizeAdaptiveFloatPoolCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AFPC-") {
            return clean
        }
        return "AFPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
