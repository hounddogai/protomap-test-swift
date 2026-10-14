import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackAssessmentManifestsForAssignment(_ items: [FallbackAssessmentManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveManualOutreachAssignmentsFromManifest(_ items: [FallbackAssessmentManifest]) -> [ManualOutreachAssignment] {
        var out: [ManualOutreachAssignment] = []
        for item in items {
            let derived = newManualOutreachAssignment(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateManualOutreachAssignment(_ item: ManualOutreachAssignment) -> String {
        return classifyAssessmentAgreement(item.projectedLoad())
    }
}
