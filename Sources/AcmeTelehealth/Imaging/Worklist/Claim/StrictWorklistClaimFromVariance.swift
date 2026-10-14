import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredReadVariancesForClaim(_ items: [TieredReadVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveStrictWorklistClaimsFromVariance(_ items: [TieredReadVariance]) -> [StrictWorklistClaim] {
        var out: [StrictWorklistClaim] = []
        for item in items {
            let derived = newStrictWorklistClaim(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyStrictWorklistClaim(_ item: StrictWorklistClaim) -> String {
        return readWindowBucket(item.effectiveValue())
    }
}
