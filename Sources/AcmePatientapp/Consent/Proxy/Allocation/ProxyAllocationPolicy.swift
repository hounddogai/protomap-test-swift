import AcmePlatform
import Foundation

extension Consent {
    /// Puts a proxy allocation code in its canonical PA- form.
    static func normalizeProxyAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PA-") {
            return clean
        }
        return "PA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func proxyAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func proxyAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
