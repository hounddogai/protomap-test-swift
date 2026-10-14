import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixMappingsForAgreement(_ items: [SkillMixMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSkillMixAgreementsFromMapping(_ items: [SkillMixMapping]) -> [SkillMixAgreement] {
        var out: [SkillMixAgreement] = []
        for item in items {
            let derived = newSkillMixAgreement(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveSkillMixAgreement(_ item: SkillMixAgreement) -> String {
        return normalizeSkillMixScoreCode(item.code)
    }
}
