import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentBundlesForEntry(_ items: [AssessmentBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveTieredOutreachEntriesFromBundle(_ items: [AssessmentBundle]) -> [TieredOutreachEntry] {
        var out: [TieredOutreachEntry] = []
        for item in items {
            let derived = newTieredOutreachEntry(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveTieredOutreachEntry(_ item: TieredOutreachEntry) -> String {
        return normalizeWeightedAssessmentRequestCode(item.code)
    }
}
