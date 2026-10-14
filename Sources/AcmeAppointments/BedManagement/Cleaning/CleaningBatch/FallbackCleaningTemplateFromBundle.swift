import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningBundlesForTemplate(_ items: [CleaningBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackCleaningTemplatesFromBundle(_ items: [CleaningBundle]) -> [FallbackCleaningTemplate] {
        var out: [FallbackCleaningTemplate] = []
        for item in items {
            let derived = newFallbackCleaningTemplate(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyFallbackCleaningTemplate(_ item: FallbackCleaningTemplate) -> Double {
        return batchedCleaningRecordWeight(8, active: true)
    }
}
