import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRollingProgramDraftsForLedger(_ items: [RollingProgramDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveAssessmentLedgersFromDraft(_ items: [RollingProgramDraft]) -> [AssessmentLedger] {
        var out: [AssessmentLedger] = []
        for item in items {
            let derived = newAssessmentLedger(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleAssessmentLedger(_ item: AssessmentLedger) -> String {
        return normalizeCappedProgramDigestCode(item.code)
    }
}
