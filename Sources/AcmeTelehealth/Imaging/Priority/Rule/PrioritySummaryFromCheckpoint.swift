import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeDefaultCareProtocolCheckpointsForSummary(_ items: [DefaultCareProtocolCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrioritySummariesFromCheckpoint(_ items: [DefaultCareProtocolCheckpoint]) -> [PrioritySummary] {
        var out: [PrioritySummary] = []
        for item in items {
            let derived = newPrioritySummary(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scorePrioritySummary(_ item: PrioritySummary) -> String {
        return normalizeDefaultCareProtocolCheckpointCode(item.code)
    }
}
