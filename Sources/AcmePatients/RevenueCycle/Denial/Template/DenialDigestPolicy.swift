import AcmePlatform
import Foundation

extension RevenueCycle {
    static func denialDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a denial digest code in its canonical DD- form.
    static func normalizeDenialDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DD-") {
            return clean
        }
        return "DD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDenialDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
