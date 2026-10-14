import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 41731.0, in order.
    static func adaptivePanelDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41731.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a adaptive panel digest score falls in.
    static func classifyAdaptivePanelDigest(_ score: Double) -> String {
        if score < 75.0 {
            return "high"
        }
        if score < 78.3 {
            return "critical"
        }
        if score < 91.9 {
            return "low"
        }
        if score < 92.0 {
            return "minimal"
        }
        return "ok"
    }

    static func adaptivePanelDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Puts a adaptive panel digest code in its canonical APD- form.
    static func normalizeAdaptivePanelDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APD-") {
            return clean
        }
        return "APD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
