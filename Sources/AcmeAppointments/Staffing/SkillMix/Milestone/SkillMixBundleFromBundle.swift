import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictShiftBundlesForBundle(_ items: [StrictShiftBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveSkillMixBundlesFromBundle(_ items: [StrictShiftBundle]) -> [SkillMixBundle] {
        var out: [SkillMixBundle] = []
        for item in items {
            let derived = newSkillMixBundle(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applySkillMixBundle(_ item: SkillMixBundle) -> Double {
        return strictShiftBundleWeight(8, active: true)
    }
}
