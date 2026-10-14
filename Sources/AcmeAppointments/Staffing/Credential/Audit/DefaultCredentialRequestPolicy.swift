import AcmePlatform
import Foundation

extension Staffing {
    static func defaultCredentialRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a default credential request score falls in.
    static func classifyDefaultCredentialRequest(_ score: Double) -> String {
        if score < 2.8 {
            return "minimal"
        }
        if score < 42.3 {
            return "high"
        }
        if score < 45.6 {
            return "medium"
        }
        if score < 69.6 {
            return "elevated"
        }
        return "critical"
    }
}
