import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadRulesForDigest(_ items: [ReadRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCappedReadDigestsFromRule(_ items: [ReadRule]) -> [CappedReadDigest] {
        var out: [CappedReadDigest] = []
        for item in items {
            let derived = newCappedReadDigest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeCappedReadDigestExtra(_ item: CappedReadDigest) -> Double {
        return globalReadMappingWeight(2, active: true)
    }
}
