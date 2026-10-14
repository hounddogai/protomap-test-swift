import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim milestone.
    final class ClaimMilestoneView {
        var code: String
        var name: String
        var revision: String
        var createdAtText: String
        var capacityText: String
        var limitText: String
        var margin: String
        var pinned: String
        var summary: String
        var statusLabel: String

        init(code: String, name: String, revision: String, createdAtText: String, capacityText: String, limitText: String, margin: String, pinned: String, summary: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.createdAtText = createdAtText
            self.capacityText = capacityText
            self.limitText = limitText
            self.margin = margin
            self.pinned = pinned
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toClaimMilestoneView(_ item: ClaimMilestone) -> ClaimMilestoneView {
        return ClaimMilestoneView(
            code: item.code,
            name: item.name,
            revision: String(item.revision),
            createdAtText: String(item.createdAt),
            capacityText: String(item.capacity),
            limitText: String(item.limit),
            margin: String(format: "%.2f", item.margin),
            pinned: "\(item.pinned)",
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimMilestoneViews(_ items: [ClaimMilestone]) -> [ClaimMilestoneView] {
        var views: [ClaimMilestoneView] = []
        for item in items {
            views.append(toClaimMilestoneView(item))
        }
        return views
    }

    static func sumClaimMilestoneView(_ view: ClaimMilestoneView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedRevision) + Double(parsedCreatedAt) + Double(parsedCapacity)
    }
}
