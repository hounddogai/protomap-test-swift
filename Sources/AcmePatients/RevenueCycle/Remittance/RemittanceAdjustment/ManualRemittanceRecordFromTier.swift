import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedChargeTiersForRecord(_ items: [CappedChargeTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveManualRemittanceRecordsFromTier(_ items: [CappedChargeTier]) -> [ManualRemittanceRecord] {
        var out: [ManualRemittanceRecord] = []
        for item in items {
            let derived = newManualRemittanceRecord(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveManualRemittanceRecord(_ item: ManualRemittanceRecord) -> String {
        return classifyLenientChargeDigest(item.adjustedTotal())
    }
}
