import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a read policy score falls in.
    static func classifyReadPolicy(_ score: Double) -> String {
        if score < 24.8 {
            return "ok"
        }
        if score < 26.5 {
            return "watch"
        }
        if score < 38.1 {
            return "minimal"
        }
        if score < 55.0 {
            return "elevated"
        }
        return "low"
    }

    static func readPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
