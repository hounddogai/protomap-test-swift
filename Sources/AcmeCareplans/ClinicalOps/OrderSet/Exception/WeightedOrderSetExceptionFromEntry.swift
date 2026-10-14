import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyOrderSetEntriesForException(_ items: [LegacyOrderSetEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveWeightedOrderSetExceptionsFromEntry(_ items: [LegacyOrderSetEntry]) -> [WeightedOrderSetException] {
        var out: [WeightedOrderSetException] = []
        for item in items {
            let derived = newWeightedOrderSetException(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateWeightedOrderSetException(_ item: WeightedOrderSetException) -> String {
        return normalizeLegacyOrderSetReservationCode(item.code)
    }
}
