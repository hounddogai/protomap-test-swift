import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a manual program window code in its canonical MPW- form.
    static func normalizeManualProgramWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MPW-") {
            return clean
        }
        return "MPW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualProgramWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-program-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a manual program window score falls in.
    static func classifyManualProgramWindow(_ score: Double) -> String {
        if score < 61.7 {
            return "minimal"
        }
        if score < 75.6 {
            return "high"
        }
        return "watch"
    }

    static func manualProgramWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
