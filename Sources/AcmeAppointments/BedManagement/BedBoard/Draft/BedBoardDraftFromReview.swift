import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyBedBoardReviewsForDraft(_ items: [LegacyBedBoardReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveBedBoardDraftsFromReview(_ items: [LegacyBedBoardReview]) -> [BedBoardDraft] {
        var out: [BedBoardDraft] = []
        for item in items {
            let derived = newBedBoardDraft(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignBedBoardDraft(_ item: BedBoardDraft) -> Double {
        return legacyBedBoardReviewWeight(7, active: true)
    }
}
