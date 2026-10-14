import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeRecordsForTier(_ items: [ReferenceRangeRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func derivePanelTiersFromRecord(_ items: [ReferenceRangeRecord]) -> [PanelTier] {
        var out: [PanelTier] = []
        for item in items {
            let derived = newPanelTier(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settlePanelTier(_ item: PanelTier) -> String {
        return referenceRangeRecordBucket(item.adjustedExposure())
    }
}
