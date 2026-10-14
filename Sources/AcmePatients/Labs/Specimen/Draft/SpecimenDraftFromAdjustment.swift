import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedAccessionAdjustmentsForDraft(_ items: [CappedAccessionAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveSpecimenDraftsFromAdjustment(_ items: [CappedAccessionAdjustment]) -> [SpecimenDraft] {
        var out: [SpecimenDraft] = []
        for item in items {
            let derived = newSpecimenDraft(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeSpecimenDraft(_ item: SpecimenDraft) -> String {
        return normalizeAccessionAgreementCode(item.code)
    }
}
