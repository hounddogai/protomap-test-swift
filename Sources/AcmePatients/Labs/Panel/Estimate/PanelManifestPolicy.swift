import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePanelManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("panel-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func panelManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a panel manifest code in its canonical PM- form.
    static func normalizePanelManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PM-") {
            return clean
        }
        return "PM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a panel manifest score falls in.
    static func classifyPanelManifest(_ score: Double) -> String {
        if score < 67.4 {
            return "critical"
        }
        if score < 99.8 {
            return "medium"
        }
        return "low"
    }
}
