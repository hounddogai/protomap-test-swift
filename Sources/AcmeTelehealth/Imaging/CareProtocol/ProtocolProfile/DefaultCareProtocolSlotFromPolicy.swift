import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeSeasonalCareProtocolPoliciesForSlot(_ items: [SeasonalCareProtocolPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultCareProtocolSlotsFromPolicy(_ items: [SeasonalCareProtocolPolicy]) -> [DefaultCareProtocolSlot] {
        var out: [DefaultCareProtocolSlot] = []
        for item in items {
            let derived = newDefaultCareProtocolSlot(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultCareProtocolSlot(_ item: DefaultCareProtocolSlot) -> String {
        return classifySeasonalCareProtocolPolicy(item.effectiveExposure())
    }
}
