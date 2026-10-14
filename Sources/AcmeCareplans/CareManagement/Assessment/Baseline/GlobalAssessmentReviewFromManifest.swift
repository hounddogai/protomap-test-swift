import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramManifestsForReview(_ items: [ProgramManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveGlobalAssessmentReviewsFromManifest(_ items: [ProgramManifest]) -> [GlobalAssessmentReview] {
        var out: [GlobalAssessmentReview] = []
        for item in items {
            let derived = newGlobalAssessmentReview(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeGlobalAssessmentReview(_ item: GlobalAssessmentReview) -> String {
        return classifyProgramManifest(item.netValue())
    }
}
