import AcmePlatform
import Foundation

extension Pharmacy {
    static func dispenseTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a dispense target code in its canonical DT- form.
    static func normalizeDispenseTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DT-") {
            return clean
        }
        return "DT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dispenseTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
