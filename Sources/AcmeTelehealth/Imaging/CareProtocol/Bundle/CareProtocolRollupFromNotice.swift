import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveWorklistNoticesForRollup(_ items: [AdaptiveWorklistNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCareProtocolRollupsFromNotice(_ items: [AdaptiveWorklistNotice]) -> [CareProtocolRollup] {
        var out: [CareProtocolRollup] = []
        for item in items {
            let derived = newCareProtocolRollup(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectCareProtocolRollup(_ item: CareProtocolRollup) -> String {
        return classifyAdaptiveWorklistNotice(item.netValue())
    }
}
