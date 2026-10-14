import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board variance.
    final class BedBoardVarianceView {
        var code: String
        var title: String
        var minimum: String
        var limit: String
        var approved: String
        var segment: String
        var statusLabel: String

        init(code: String, title: String, minimum: String, limit: String, approved: String, segment: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.limit = limit
            self.approved = approved
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardVarianceView(_ item: BedBoardVariance) -> BedBoardVarianceView {
        return BedBoardVarianceView(
            code: item.code,
            title: item.title,
            minimum: String(format: "%.2f", item.minimum),
            limit: String(item.limit),
            approved: "\(item.approved)",
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardVarianceViews(_ items: [BedBoardVariance]) -> [BedBoardVarianceView] {
        var views: [BedBoardVarianceView] = []
        for item in items {
            views.append(toBedBoardVarianceView(item))
        }
        return views
    }

    static func sumBedBoardVarianceView(_ view: BedBoardVarianceView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMinimum + Double(parsedLimit)
    }
}
