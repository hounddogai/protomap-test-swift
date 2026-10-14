import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding milestone.
    final class RoundingMilestoneView {
        var code: String
        var nameText: String
        var rate: String
        var label: String
        var limit: String
        var localeText: String
        var notes: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, nameText: String, rate: String, label: String, limit: String, localeText: String, notes: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.rate = rate
            self.label = label
            self.limit = limit
            self.localeText = localeText
            self.notes = notes
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingMilestoneView(_ item: RoundingMilestone) -> RoundingMilestoneView {
        return RoundingMilestoneView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            rate: String(format: "%.2f", item.rate),
            label: item.label,
            limit: String(item.limit),
            localeText: item.locale,
            notes: item.notes,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingMilestoneViews(_ items: [RoundingMilestone]) -> [RoundingMilestoneView] {
        var views: [RoundingMilestoneView] = []
        for item in items {
            views.append(toRoundingMilestoneView(item))
        }
        return views
    }

    static func sumRoundingMilestoneView(_ view: RoundingMilestoneView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedRate + Double(parsedLimit)
    }
}
