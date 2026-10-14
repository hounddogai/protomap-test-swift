import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyCareProtocolDigestsForLedger(_ items: [LegacyCareProtocolDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredHandoffLedgersFromDigest(_ items: [LegacyCareProtocolDigest]) -> [TieredHandoffLedger] {
        var out: [TieredHandoffLedger] = []
        for item in items {
            let derived = newTieredHandoffLedger(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignTieredHandoffLedger(_ item: TieredHandoffLedger) -> String {
        return manualCareProtocolTemplateBucket(item.measuredValue())
    }
}
