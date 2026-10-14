import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a primary proxy checkpoint score falls in.
    static func classifyPrimaryProxyCheckpoint(_ score: Double) -> String {
        if score < 5.6 {
            return "minimal"
        }
        if score < 17.4 {
            return "critical"
        }
        if score < 65.0 {
            return "high"
        }
        if score < 82.1 {
            return "ok"
        }
        return "medium"
    }

    /// Puts a primary proxy checkpoint code in its canonical PPC- form.
    static func normalizePrimaryProxyCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPC-") {
            return clean
        }
        return "PPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePrimaryProxyCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 59037.0, in order.
    static func primaryProxyCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59037.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
