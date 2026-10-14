import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 94169.0, in order.
    static func outreachWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94169.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a outreach window code in its canonical OW- form.
    static func normalizeOutreachWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OW-") {
            return clean
        }
        return "OW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeOutreachWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a outreach window score falls in.
    static func classifyOutreachWindow(_ score: Double) -> String {
        if score < 15.1 {
            return "critical"
        }
        if score < 20.1 {
            return "minimal"
        }
        if score < 55.5 {
            return "low"
        }
        if score < 73.1 {
            return "high"
        }
        return "watch"
    }
}
