import AcmePlatform
import Foundation

extension Labs {
    static func adaptivePanelAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a adaptive panel allocation code in its canonical APA- form.
    static func normalizeAdaptivePanelAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APA-") {
            return clean
        }
        return "APA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptivePanelAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
