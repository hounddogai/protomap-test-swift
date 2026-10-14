import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptiveSpecimenTemplatesForAudit(_ items: [AdaptiveSpecimenTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveTieredPanelAuditsFromTemplate(_ items: [AdaptiveSpecimenTemplate]) -> [TieredPanelAudit] {
        var out: [TieredPanelAudit] = []
        for item in items {
            let derived = newTieredPanelAudit(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planTieredPanelAudit(_ item: TieredPanelAudit) -> String {
        return normalizeManualSpecimenSegmentCode(item.code)
    }
}
