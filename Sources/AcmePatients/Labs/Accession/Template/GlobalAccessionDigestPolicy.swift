import AcmePlatform
import Foundation

extension Labs {
    static func globalAccessionDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a global accession digest score falls in.
    static func classifyGlobalAccessionDigest(_ score: Double) -> String {
        if score < 20.0 {
            return "watch"
        }
        if score < 30.7 {
            return "medium"
        }
        if score < 78.2 {
            return "critical"
        }
        if score < 84.0 {
            return "ok"
        }
        return "low"
    }
}
