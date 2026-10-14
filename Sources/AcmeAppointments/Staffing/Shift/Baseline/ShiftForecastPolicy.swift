import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeShiftForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("shift-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a shift forecast code in its canonical SF- form.
    static func normalizeShiftForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SF-") {
            return clean
        }
        return "SF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
