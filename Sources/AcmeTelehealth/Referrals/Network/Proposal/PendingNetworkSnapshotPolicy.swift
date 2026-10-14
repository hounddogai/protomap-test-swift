import AcmePlatform
import Foundation

extension Referrals {
    static func pendingNetworkSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a pending network snapshot code in its canonical PNS- form.
    static func normalizePendingNetworkSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PNS-") {
            return clean
        }
        return "PNS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingNetworkSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
