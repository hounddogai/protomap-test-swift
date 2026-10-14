import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 22333.0, in order.
    static func worklistManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22333.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func worklistManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func worklistManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a worklist manifest code in its canonical WM- form.
    static func normalizeWorklistManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WM-") {
            return clean
        }
        return "WM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
