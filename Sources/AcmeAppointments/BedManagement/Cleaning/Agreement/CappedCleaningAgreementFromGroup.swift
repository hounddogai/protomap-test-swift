import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedTransferGroupsForAgreement(_ items: [WeightedTransferGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCappedCleaningAgreementsFromGroup(_ items: [WeightedTransferGroup]) -> [CappedCleaningAgreement] {
        var out: [CappedCleaningAgreement] = []
        for item in items {
            let derived = newCappedCleaningAgreement(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankCappedCleaningAgreement(_ item: CappedCleaningAgreement) -> String {
        return normalizeWeightedTransferGroupCode(item.code)
    }
}
