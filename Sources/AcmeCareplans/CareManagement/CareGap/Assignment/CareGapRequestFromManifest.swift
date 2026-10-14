import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentManifestsForRequest(_ items: [AssessmentManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCareGapRequestsFromManifest(_ items: [AssessmentManifest]) -> [CareGapRequest] {
        var out: [CareGapRequest] = []
        for item in items {
            let derived = newCareGapRequest(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeCareGapRequest(_ item: CareGapRequest) -> String {
        return classifyAssessmentManifest(item.measuredValue())
    }
}
