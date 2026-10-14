import AcmePlatform
import Foundation

extension Consent {
    static func proxyNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a proxy notice code in its canonical PN- form.
    static func normalizeProxyNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PN-") {
            return clean
        }
        return "PN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
