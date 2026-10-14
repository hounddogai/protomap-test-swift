import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeProfilesForAgreement(_ items: [ReferenceRangeProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveAccessionAgreementsFromProfile(_ items: [ReferenceRangeProfile]) -> [AccessionAgreement] {
        var out: [AccessionAgreement] = []
        for item in items {
            let derived = newAccessionAgreement(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleAccessionAgreement(_ item: AccessionAgreement) -> String {
        return classifyReferenceRangeEntry(item.adjustedVolume())
    }
}
