import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered shift summary.
    final class TieredShiftSummaryView {
        var code: String
        var titleText: String
        var updatedAt: String
        var minimum: String
        var contactEmail: String
        var marginText: String
        var dosageMg: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, titleText: String, updatedAt: String, minimum: String, contactEmail: String, marginText: String, dosageMg: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.updatedAt = updatedAt
            self.minimum = minimum
            self.contactEmail = contactEmail
            self.marginText = marginText
            self.dosageMg = dosageMg
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredShiftSummaryView(_ item: TieredShiftSummary) -> TieredShiftSummaryView {
        return TieredShiftSummaryView(
            code: item.code,
            titleText: item.title,
            updatedAt: String(item.updatedAt),
            minimum: String(format: "%.2f", item.minimum),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            marginText: String(format: "%.2f", item.margin),
            dosageMg: String(format: "%.2f", item.dosageMg),
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredShiftSummaryViews(_ items: [TieredShiftSummary]) -> [TieredShiftSummaryView] {
        var views: [TieredShiftSummaryView] = []
        for item in items {
            views.append(toTieredShiftSummaryView(item))
        }
        return views
    }

    static func sumTieredShiftSummaryView(_ view: TieredShiftSummaryView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMinimum + parsedMargin
    }
}
