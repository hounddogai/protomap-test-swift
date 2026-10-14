import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackBedBoardAdjustmentsForClaim(_ items: [FallbackBedBoardAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveTransferClaimsFromAdjustment(_ items: [FallbackBedBoardAdjustment]) -> [TransferClaim] {
        var out: [TransferClaim] = []
        for item in items {
            let derived = newTransferClaim(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyTransferClaim(_ item: TransferClaim) -> String {
        return classifyFallbackBedBoardAdjustment(item.netTotal())
    }
}
