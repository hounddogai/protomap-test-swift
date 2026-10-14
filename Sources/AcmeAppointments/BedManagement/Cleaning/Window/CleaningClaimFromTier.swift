import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferTiersForClaim(_ items: [TransferTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCleaningClaimsFromTier(_ items: [TransferTier]) -> [CleaningClaim] {
        var out: [CleaningClaim] = []
        for item in items {
            let derived = newCleaningClaim(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveCleaningClaim(_ item: CleaningClaim) -> String {
        return normalizeTransferMetricCode(item.code)
    }
}
