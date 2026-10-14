import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapManifestsForEstimate(_ items: [CareGapManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRegionalAssessmentEstimatesFromManifest(_ items: [CareGapManifest]) -> [RegionalAssessmentEstimate] {
        var out: [RegionalAssessmentEstimate] = []
        for item in items {
            let derived = newRegionalAssessmentEstimate(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalAssessmentEstimate(_ item: RegionalAssessmentEstimate) -> String {
        return classifyCareGapManifest(item.projectedVolume())
    }
}
