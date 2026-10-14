import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a bed board window score falls in.
    static func classifyBedBoardWindow(_ score: Double) -> String {
        if score < 47.9 {
            return "critical"
        }
        if score < 61.8 {
            return "high"
        }
        if score < 82.6 {
            return "low"
        }
        if score < 82.9 {
            return "minimal"
        }
        return "medium"
    }

    static func bedBoardWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBedBoardWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("bed-board-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a bed board window code in its canonical BBW- form.
    static func normalizeBedBoardWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBW-") {
            return clean
        }
        return "BBW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
