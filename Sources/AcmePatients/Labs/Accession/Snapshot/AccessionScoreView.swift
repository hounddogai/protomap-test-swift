import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession score.
    final class AccessionScoreView {
        var code: String
        var title: String
        var archived: String
        var ceiling: String
        var bedText: String
        var refills: String
        var regionText: String
        var statusLabel: String

        init(code: String, title: String, archived: String, ceiling: String, bedText: String, refills: String, regionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.archived = archived
            self.ceiling = ceiling
            self.bedText = bedText
            self.refills = refills
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionScoreView(_ item: AccessionScore) -> AccessionScoreView {
        return AccessionScoreView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 40),
            archived: "\(item.archived)",
            ceiling: String(format: "%.2f", item.ceiling),
            bedText: item.bed,
            refills: String(item.refills),
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionScoreViews(_ items: [AccessionScore]) -> [AccessionScoreView] {
        var views: [AccessionScoreView] = []
        for item in items {
            views.append(toAccessionScoreView(item))
        }
        return views
    }

    static func sumAccessionScoreView(_ view: AccessionScoreView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedCeiling + Double(parsedRefills)
    }
}
