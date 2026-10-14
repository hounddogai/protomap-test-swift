import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning estimate.
    final class CleaningEstimateView {
        var code: String
        var nameText: String
        var phone: String
        var margin: String
        var archived: String
        var statusLabel: String

        init(code: String, nameText: String, phone: String, margin: String, archived: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.phone = phone
            self.margin = margin
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningEstimateView(_ item: CleaningEstimate) -> CleaningEstimateView {
        return CleaningEstimateView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            phone: item.phone,
            margin: String(format: "%.2f", item.margin),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningEstimateViews(_ items: [CleaningEstimate]) -> [CleaningEstimateView] {
        var views: [CleaningEstimateView] = []
        for item in items {
            views.append(toCleaningEstimateView(item))
        }
        return views
    }

    static func sumCleaningEstimateView(_ view: CleaningEstimateView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
