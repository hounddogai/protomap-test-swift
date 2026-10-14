import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictShiftDigestsForBundle(_ items: [StrictShiftDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictCredentialBundlesFromDigest(_ items: [StrictShiftDigest]) -> [StrictCredentialBundle] {
        var out: [StrictCredentialBundle] = []
        for item in items {
            let derived = newStrictCredentialBundle(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchStrictCredentialBundle(_ item: StrictCredentialBundle) -> Double {
        return defaultShiftTemplateWeight(3, active: true)
    }
}
