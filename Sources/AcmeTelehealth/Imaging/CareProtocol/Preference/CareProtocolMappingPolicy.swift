import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a care protocol mapping score falls in.
    static func classifyCareProtocolMapping(_ score: Double) -> String {
        if score < 53.6 {
            return "watch"
        }
        if score < 64.9 {
            return "elevated"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCareProtocolMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careProtocolMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
