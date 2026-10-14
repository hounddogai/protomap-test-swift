import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction milestone.
    final class InteractionMilestoneView {
        var codeText: String
        var name: String
        var durationMinutes: String
        var summary: String
        var createdAtText: String
        var archived: String
        var statusLabel: String

        init(codeText: String, name: String, durationMinutes: String, summary: String, createdAtText: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.durationMinutes = durationMinutes
            self.summary = summary
            self.createdAtText = createdAtText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionMilestoneView(_ item: InteractionMilestone) -> InteractionMilestoneView {
        return InteractionMilestoneView(
            codeText: item.code,
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            summary: item.summary,
            createdAtText: String(item.createdAt),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionMilestoneViews(_ items: [InteractionMilestone]) -> [InteractionMilestoneView] {
        var views: [InteractionMilestoneView] = []
        for item in items {
            views.append(toInteractionMilestoneView(item))
        }
        return views
    }

    static func sumInteractionMilestoneView(_ view: InteractionMilestoneView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedCreatedAt)
    }
}
