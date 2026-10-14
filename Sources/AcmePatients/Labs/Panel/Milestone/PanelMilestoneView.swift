import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel milestone.
    final class PanelMilestoneView {
        var codeText: String
        var name: String
        var specialty: String
        var region: String
        var title: String
        var attemptsText: String
        var updatedAt: String
        var country: String
        var statusLabel: String

        init(codeText: String, name: String, specialty: String, region: String, title: String, attemptsText: String, updatedAt: String, country: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.specialty = specialty
            self.region = region
            self.title = title
            self.attemptsText = attemptsText
            self.updatedAt = updatedAt
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toPanelMilestoneView(_ item: PanelMilestone) -> PanelMilestoneView {
        return PanelMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            region: item.region,
            title: item.title,
            attemptsText: String(item.attempts),
            updatedAt: String(item.updatedAt),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelMilestoneViews(_ items: [PanelMilestone]) -> [PanelMilestoneView] {
        var views: [PanelMilestoneView] = []
        for item in items {
            views.append(toPanelMilestoneView(item))
        }
        return views
    }

    static func sumPanelMilestoneView(_ view: PanelMilestoneView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedUpdatedAt)
    }
}
