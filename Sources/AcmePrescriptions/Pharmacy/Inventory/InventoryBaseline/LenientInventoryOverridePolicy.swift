import AcmePlatform
import Foundation

extension Pharmacy {
    static func lenientInventoryOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientInventoryOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-inventory-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient inventory override code in its canonical LIO- form.
    static func normalizeLenientInventoryOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LIO-") {
            return clean
        }
        return "LIO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
