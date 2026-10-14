import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range group.
    final class ReferenceRangeGroupView {
        var code: String
        var labelText: String
        var name: String
        var title: String
        var active: String
        var ceiling: String
        var reviewer: String
        var limit: String
        var startsAt: String
        var statusLabel: String

        init(code: String, labelText: String, name: String, title: String, active: String, ceiling: String, reviewer: String, limit: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.name = name
            self.title = title
            self.active = active
            self.ceiling = ceiling
            self.reviewer = reviewer
            self.limit = limit
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeGroupView(_ item: ReferenceRangeGroup) -> ReferenceRangeGroupView {
        return ReferenceRangeGroupView(
            code: item.code,
            labelText: item.label,
            name: item.name,
            title: item.title,
            active: "\(item.active)",
            ceiling: String(format: "%.2f", item.ceiling),
            reviewer: item.reviewer,
            limit: String(item.limit),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeGroupViews(_ items: [ReferenceRangeGroup]) -> [ReferenceRangeGroupView] {
        var views: [ReferenceRangeGroupView] = []
        for item in items {
            views.append(toReferenceRangeGroupView(item))
        }
        return views
    }

    static func sumReferenceRangeGroupView(_ view: ReferenceRangeGroupView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedCeiling + Double(parsedLimit) + Double(parsedStartsAt)
    }
}
