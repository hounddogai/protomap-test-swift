import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeNoticesForAgreement(_ items: [ReferenceRangeNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveSpecimenAgreementsFromNotice(_ items: [ReferenceRangeNotice]) -> [SpecimenAgreement] {
        var out: [SpecimenAgreement] = []
        for item in items {
            let derived = newSpecimenAgreement(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchSpecimenAgreement(_ item: SpecimenAgreement) -> Double {
        return defaultReferenceRangeAssignmentWeight(1, active: true)
    }
}
