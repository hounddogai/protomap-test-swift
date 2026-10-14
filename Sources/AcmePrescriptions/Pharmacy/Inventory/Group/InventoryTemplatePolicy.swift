import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func inventoryTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a inventory template code in its canonical IT- form.
    static func normalizeInventoryTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IT-") {
            return clean
        }
        return "IT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
