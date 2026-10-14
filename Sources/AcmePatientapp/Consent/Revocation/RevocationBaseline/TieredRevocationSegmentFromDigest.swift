import AcmePlatform
import Foundation

extension Consent {
    static func summarizeBatchedRevocationDigestsForSegment(_ items: [BatchedRevocationDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveTieredRevocationSegmentsFromDigest(_ items: [BatchedRevocationDigest]) -> [TieredRevocationSegment] {
        var out: [TieredRevocationSegment] = []
        for item in items {
            let derived = newTieredRevocationSegment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchTieredRevocationSegment(_ item: TieredRevocationSegment) -> String {
        return classifyCappedRevocationBundle(item.effectiveExposure())
    }
}
