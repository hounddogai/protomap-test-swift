import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingInteractionAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-interaction-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a pending interaction allocation score falls in.
    static func classifyPendingInteractionAllocation(_ score: Double) -> String {
        if score < 34.1 {
            return "watch"
        }
        if score < 80.2 {
            return "critical"
        }
        if score < 93.6 {
            return "elevated"
        }
        return "ok"
    }

    static func mergePendingInteractionAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a pending interaction allocation code in its canonical PIA- form.
    static func normalizePendingInteractionAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIA-") {
            return clean
        }
        return "PIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
