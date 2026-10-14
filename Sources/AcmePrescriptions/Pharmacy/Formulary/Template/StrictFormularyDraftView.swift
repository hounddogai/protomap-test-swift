import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict formulary draft.
    final class StrictFormularyDraftView {
        var code: String
        var title: String
        var updatedAt: String
        var refills: String
        var ceiling: String
        var statusLabel: String

        init(code: String, title: String, updatedAt: String, refills: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.refills = refills
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toStrictFormularyDraftView(_ item: StrictFormularyDraft) -> StrictFormularyDraftView {
        return StrictFormularyDraftView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            updatedAt: String(item.updatedAt),
            refills: String(item.refills),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictFormularyDraftViews(_ items: [StrictFormularyDraft]) -> [StrictFormularyDraftView] {
        var views: [StrictFormularyDraftView] = []
        for item in items {
            views.append(toStrictFormularyDraftView(item))
        }
        return views
    }

    static func sumStrictFormularyDraftView(_ view: StrictFormularyDraftView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedRefills) + parsedCeiling
    }
}
