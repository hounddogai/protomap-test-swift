import AcmePlatform
import Foundation

extension Labs {
    static func globalCourierMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func globalCourierMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a global courier mapping code in its canonical GCM- form.
    static func normalizeGlobalCourierMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCM-") {
            return clean
        }
        return "GCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
