import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered closure milestone.
    final class TieredClosureMilestoneView {
        var code: String
        var title: String
        var unit: String
        var capacity: String
        var ownerID: String
        var bed: String
        var refills: String
        var expiresAt: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, unit: String, capacity: String, ownerID: String, bed: String, refills: String, expiresAt: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.unit = unit
            self.capacity = capacity
            self.ownerID = ownerID
            self.bed = bed
            self.refills = refills
            self.expiresAt = expiresAt
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toTieredClosureMilestoneView(_ item: TieredClosureMilestone) -> TieredClosureMilestoneView {
        return TieredClosureMilestoneView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            unit: item.unit,
            capacity: String(item.capacity),
            ownerID: item.ownerID,
            bed: item.bed,
            refills: String(item.refills),
            expiresAt: String(item.expiresAt),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredClosureMilestoneViews(_ items: [TieredClosureMilestone]) -> [TieredClosureMilestoneView] {
        var views: [TieredClosureMilestoneView] = []
        for item in items {
            views.append(toTieredClosureMilestoneView(item))
        }
        return views
    }

    static func sumTieredClosureMilestoneView(_ view: TieredClosureMilestoneView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedCapacity) + Double(parsedRefills) + Double(parsedExpiresAt)
    }
}
