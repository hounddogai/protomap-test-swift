import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional study variance.
    final class RegionalStudyVarianceView {
        var code: String
        var title: String
        var visitMinutes: String
        var graceDays: String
        var ratio: String
        var updatedAtText: String
        var archived: String
        var statusLabel: String

        init(code: String, title: String, visitMinutes: String, graceDays: String, ratio: String, updatedAtText: String, archived: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.ratio = ratio
            self.updatedAtText = updatedAtText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalStudyVarianceView(_ item: RegionalStudyVariance) -> RegionalStudyVarianceView {
        return RegionalStudyVarianceView(
            code: item.code,
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            graceDays: String(item.graceDays),
            ratio: String(format: "%.2f", item.ratio),
            updatedAtText: String(item.updatedAt),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalStudyVarianceViews(_ items: [RegionalStudyVariance]) -> [RegionalStudyVarianceView] {
        var views: [RegionalStudyVarianceView] = []
        for item in items {
            views.append(toRegionalStudyVarianceView(item))
        }
        return views
    }

    static func sumRegionalStudyVarianceView(_ view: RegionalStudyVarianceView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedGraceDays) + parsedRatio
    }
}
