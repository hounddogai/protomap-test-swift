import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningTemplatesForTemplate(_ items: [CleaningTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveGlobalTransferTemplatesFromTemplate(_ items: [CleaningTemplate]) -> [GlobalTransferTemplate] {
        var out: [GlobalTransferTemplate] = []
        for item in items {
            let derived = newGlobalTransferTemplate(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyGlobalTransferTemplate(_ item: GlobalTransferTemplate) -> String {
        return classifyCleaningTemplate(item.projectedLoad())
    }
}
