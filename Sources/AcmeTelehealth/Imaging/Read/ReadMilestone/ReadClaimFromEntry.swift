import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredWorklistEntriesForClaim(_ items: [TieredWorklistEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveReadClaimsFromEntry(_ items: [TieredWorklistEntry]) -> [ReadClaim] {
        var out: [ReadClaim] = []
        for item in items {
            let derived = newReadClaim(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitReadClaim(_ item: ReadClaim) -> String {
        return classifyTieredWorklistEntry(item.adjustedTotal())
    }
}
