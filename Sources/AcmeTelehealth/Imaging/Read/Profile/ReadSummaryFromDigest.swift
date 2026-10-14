import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrimaryWorklistDigestsForSummary(_ items: [PrimaryWorklistDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveReadSummariesFromDigest(_ items: [PrimaryWorklistDigest]) -> [ReadSummary] {
        var out: [ReadSummary] = []
        for item in items {
            let derived = newReadSummary(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateReadSummary(_ item: ReadSummary) -> String {
        return primaryWorklistDigestBucket(item.measuredValue())
    }
}
