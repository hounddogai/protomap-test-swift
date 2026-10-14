import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackCareGapEntriesForOverride(_ items: [FallbackCareGapEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveDefaultProgramOverridesFromEntry(_ items: [FallbackCareGapEntry]) -> [DefaultProgramOverride] {
        var out: [DefaultProgramOverride] = []
        for item in items {
            let derived = newDefaultProgramOverride(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planDefaultProgramOverride(_ item: DefaultProgramOverride) -> Double {
        return rollingCareGapDigestWeight(1, active: true)
    }
}
