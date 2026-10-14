import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalCourierTiersForAgreement(_ items: [GlobalCourierTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveLegacyAccessionAgreementsFromTier(_ items: [GlobalCourierTier]) -> [LegacyAccessionAgreement] {
        var out: [LegacyAccessionAgreement] = []
        for item in items {
            let derived = newLegacyAccessionAgreement(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLegacyAccessionAgreement(_ item: LegacyAccessionAgreement) -> String {
        return normalizeCappedCourierExceptionCode(item.code)
    }
}
