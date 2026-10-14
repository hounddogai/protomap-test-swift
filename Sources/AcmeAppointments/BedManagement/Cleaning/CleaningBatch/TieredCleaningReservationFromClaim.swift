import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBatchedTransferClaimsForReservation(_ items: [BatchedTransferClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveTieredCleaningReservationsFromClaim(_ items: [BatchedTransferClaim]) -> [TieredCleaningReservation] {
        var out: [TieredCleaningReservation] = []
        for item in items {
            let derived = newTieredCleaningReservation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceTieredCleaningReservation(_ item: TieredCleaningReservation) -> String {
        return classifyCappedTransferThreshold(item.projectedTotal())
    }
}
