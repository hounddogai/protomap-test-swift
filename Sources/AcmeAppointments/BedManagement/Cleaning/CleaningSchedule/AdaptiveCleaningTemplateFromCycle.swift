import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeStrictBedBoardCyclesForTemplate(_ items: [StrictBedBoardCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveAdaptiveCleaningTemplatesFromCycle(_ items: [StrictBedBoardCycle]) -> [AdaptiveCleaningTemplate] {
        var out: [AdaptiveCleaningTemplate] = []
        for item in items {
            let derived = newAdaptiveCleaningTemplate(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignAdaptiveCleaningTemplate(_ item: AdaptiveCleaningTemplate) -> String {
        return classifyBedBoardMetric(item.netLoad())
    }
}
