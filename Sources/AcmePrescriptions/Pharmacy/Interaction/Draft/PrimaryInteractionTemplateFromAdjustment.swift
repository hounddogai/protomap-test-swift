import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionAdjustmentsForTemplate(_ items: [SubstitutionAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePrimaryInteractionTemplatesFromAdjustment(_ items: [SubstitutionAdjustment]) -> [PrimaryInteractionTemplate] {
        var out: [PrimaryInteractionTemplate] = []
        for item in items {
            let derived = newPrimaryInteractionTemplate(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizePrimaryInteractionTemplate(_ item: PrimaryInteractionTemplate) -> String {
        return substitutionAdjustmentBucket(item.projectedVolume())
    }
}
