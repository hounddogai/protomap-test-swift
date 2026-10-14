import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallNoticesForBaseline(_ items: [RecallNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictInteractionBaselinesFromNotice(_ items: [RecallNotice]) -> [StrictInteractionBaseline] {
        var out: [StrictInteractionBaseline] = []
        for item in items {
            let derived = newStrictInteractionBaseline(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceStrictInteractionBaseline(_ item: StrictInteractionBaseline) -> Double {
        return manualRecallGroupWeight(3, active: true)
    }
}
