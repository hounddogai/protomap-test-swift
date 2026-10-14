import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a default care protocol checkpoint score falls in.
    static func classifyDefaultCareProtocolCheckpoint(_ score: Double) -> String {
        if score < 68.5 {
            return "medium"
        }
        if score < 98.3 {
            return "ok"
        }
        return "minimal"
    }

    /// Puts a default care protocol checkpoint code in its canonical DCPC- form.
    static func normalizeDefaultCareProtocolCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCPC-") {
            return clean
        }
        return "DCPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 35254.0, in order.
    static func defaultCareProtocolCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35254.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
