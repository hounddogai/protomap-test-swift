import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramReviewsForThreshold(_ items: [ProgramReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveGlobalOutreachThresholdsFromReview(_ items: [ProgramReview]) -> [GlobalOutreachThreshold] {
        var out: [GlobalOutreachThreshold] = []
        for item in items {
            let derived = newGlobalOutreachThreshold(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeGlobalOutreachThreshold(_ item: GlobalOutreachThreshold) -> String {
        return classifyFallbackProgramBatch(item.projectedVolume())
    }
}
