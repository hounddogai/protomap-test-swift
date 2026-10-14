import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistMappingsForOverride(_ items: [WorklistMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCareProtocolOverridesFromMapping(_ items: [WorklistMapping]) -> [CareProtocolOverride] {
        var out: [CareProtocolOverride] = []
        for item in items {
            let derived = newCareProtocolOverride(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCareProtocolOverride(_ item: CareProtocolOverride) -> Double {
        return primaryWorklistNoticeWeight(5, active: true)
    }
}
