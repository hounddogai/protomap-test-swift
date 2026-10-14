import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolBaselinesForOverride(_ items: [CareProtocolBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveTieredHandoffOverridesFromBaseline(_ items: [CareProtocolBaseline]) -> [TieredHandoffOverride] {
        var out: [TieredHandoffOverride] = []
        for item in items {
            let derived = newTieredHandoffOverride(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeTieredHandoffOverride(_ item: TieredHandoffOverride) -> String {
        return classifyDefaultCareProtocolRule(item.adjustedValue())
    }
}
