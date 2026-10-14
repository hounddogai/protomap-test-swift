import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeDefaultCareProtocolSlotsForGroup(_ items: [DefaultCareProtocolSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveTieredCareProtocolGroupsFromSlot(_ items: [DefaultCareProtocolSlot]) -> [TieredCareProtocolGroup] {
        var out: [TieredCareProtocolGroup] = []
        for item in items {
            let derived = newTieredCareProtocolGroup(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitTieredCareProtocolGroup(_ item: TieredCareProtocolGroup) -> String {
        return normalizeScheduledCareProtocolProfileCode(item.code)
    }
}
