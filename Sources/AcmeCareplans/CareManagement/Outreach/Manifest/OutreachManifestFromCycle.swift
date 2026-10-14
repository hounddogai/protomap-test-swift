import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentCyclesForManifest(_ items: [AssessmentCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveOutreachManifestsFromCycle(_ items: [AssessmentCycle]) -> [OutreachManifest] {
        var out: [OutreachManifest] = []
        for item in items {
            let derived = newOutreachManifest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchOutreachManifest(_ item: OutreachManifest) -> String {
        return normalizeRegionalAssessmentManifestCode(item.code)
    }
}
