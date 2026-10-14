import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim draft.
    final class ClaimDraftView {
        var code: String
        var title: String
        var category: String
        var acuityText: String
        var score: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, title: String, category: String, acuityText: String, score: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.category = category
            self.acuityText = acuityText
            self.score = score
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toClaimDraftView(_ item: ClaimDraft) -> ClaimDraftView {
        return ClaimDraftView(
            code: item.code,
            title: item.title,
            category: item.category,
            acuityText: String(item.acuity),
            score: String(format: "%.2f", item.score),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimDraftViews(_ items: [ClaimDraft]) -> [ClaimDraftView] {
        var views: [ClaimDraftView] = []
        for item in items {
            views.append(toClaimDraftView(item))
        }
        return views
    }

    static func sumClaimDraftView(_ view: ClaimDraftView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedAcuity) + parsedScore + parsedFloorValue
    }
}
