import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered read target.
    final class TieredReadTargetView {
        var codeText: String
        var title: String
        var category: String
        var facility: String
        var marginText: String
        var reviewerText: String
        var notes: String
        var limit: String
        var statusLabel: String

        init(codeText: String, title: String, category: String, facility: String, marginText: String, reviewerText: String, notes: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.category = category
            self.facility = facility
            self.marginText = marginText
            self.reviewerText = reviewerText
            self.notes = notes
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReadTargetView(_ item: TieredReadTarget) -> TieredReadTargetView {
        return TieredReadTargetView(
            codeText: item.code,
            title: item.title,
            category: item.category,
            facility: item.facility,
            marginText: String(format: "%.2f", item.margin),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 120),
            notes: item.notes,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReadTargetViews(_ items: [TieredReadTarget]) -> [TieredReadTargetView] {
        var views: [TieredReadTargetView] = []
        for item in items {
            views.append(toTieredReadTargetView(item))
        }
        return views
    }

    static func sumTieredReadTargetView(_ view: TieredReadTargetView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMargin + Double(parsedLimit)
    }
}
