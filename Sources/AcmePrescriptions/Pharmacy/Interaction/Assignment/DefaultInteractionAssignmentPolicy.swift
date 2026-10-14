import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultInteractionAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-interaction-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a default interaction assignment code in its canonical DIA- form.
    static func normalizeDefaultInteractionAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DIA-") {
            return clean
        }
        return "DIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a default interaction assignment score falls in.
    static func classifyDefaultInteractionAssignment(_ score: Double) -> String {
        if score < 28.8 {
            return "low"
        }
        if score < 35.7 {
            return "high"
        }
        if score < 54.5 {
            return "minimal"
        }
        if score < 64.5 {
            return "elevated"
        }
        return "medium"
    }
}
