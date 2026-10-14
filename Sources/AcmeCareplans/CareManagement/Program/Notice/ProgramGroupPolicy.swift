import AcmePlatform
import Foundation

extension CareManagement {
    static func programGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a program group score falls in.
    static func classifyProgramGroup(_ score: Double) -> String {
        if score < 13.9 {
            return "elevated"
        }
        if score < 65.8 {
            return "ok"
        }
        if score < 73.1 {
            return "critical"
        }
        return "low"
    }

    /// Puts a program group code in its canonical PG- form.
    static func normalizeProgramGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PG-") {
            return clean
        }
        return "PG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func programGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
