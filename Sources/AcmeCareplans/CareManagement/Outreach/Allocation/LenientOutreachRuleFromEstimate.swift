import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultProgramEstimatesForRule(_ items: [DefaultProgramEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientOutreachRulesFromEstimate(_ items: [DefaultProgramEstimate]) -> [LenientOutreachRule] {
        var out: [LenientOutreachRule] = []
        for item in items {
            let derived = newLenientOutreachRule(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeLenientOutreachRule(_ item: LenientOutreachRule) -> String {
        return normalizeDefaultProgramEstimateCode(item.code)
    }
}
