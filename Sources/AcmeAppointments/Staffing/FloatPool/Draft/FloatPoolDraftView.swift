import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool draft.
    final class FloatPoolDraftView {
        var code: String
        var name: String
        var discount: String
        var margin: String
        var categoryText: String
        var statusLabel: String

        init(code: String, name: String, discount: String, margin: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.discount = discount
            self.margin = margin
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolDraftView(_ item: FloatPoolDraft) -> FloatPoolDraftView {
        return FloatPoolDraftView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            discount: String(format: "%.2f", item.discount),
            margin: String(format: "%.2f", item.margin),
            categoryText: Kit.Text.truncate(item.category, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolDraftViews(_ items: [FloatPoolDraft]) -> [FloatPoolDraftView] {
        var views: [FloatPoolDraftView] = []
        for item in items {
            views.append(toFloatPoolDraftView(item))
        }
        return views
    }

    static func sumFloatPoolDraftView(_ view: FloatPoolDraftView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedDiscount + parsedMargin
    }
}
