import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadAllocationsForLedger(_ items: [ReadAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveReadLedgersFromAllocation(_ items: [ReadAllocation]) -> [ReadLedger] {
        var out: [ReadLedger] = []
        for item in items {
            let derived = newReadLedger(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreReadLedger(_ item: ReadLedger) -> Double {
        return readManifestWeight(7, active: true)
    }
}
