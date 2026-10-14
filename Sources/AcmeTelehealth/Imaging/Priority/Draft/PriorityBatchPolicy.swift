import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a priority batch code in its canonical PB- form.
    static func normalizePriorityBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PB-") {
            return clean
        }
        return "PB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func priorityBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a priority batch score falls in.
    static func classifyPriorityBatch(_ score: Double) -> String {
        if score < 11.7 {
            return "medium"
        }
        if score < 22.0 {
            return "watch"
        }
        if score < 83.5 {
            return "ok"
        }
        return "minimal"
    }
}
