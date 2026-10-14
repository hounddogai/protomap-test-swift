import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling interaction segment.
    final class RollingInteractionSegmentView {
        var codeText: String
        var label: String
        var descriptionText: String
        var capacityText: String
        var weightText: String
        var endsAt: String
        var startsAt: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, label: String, descriptionText: String, capacityText: String, weightText: String, endsAt: String, startsAt: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.descriptionText = descriptionText
            self.capacityText = capacityText
            self.weightText = weightText
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toRollingInteractionSegmentView(_ item: RollingInteractionSegment) -> RollingInteractionSegmentView {
        return RollingInteractionSegmentView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            descriptionText: Kit.Text.truncate(item.description, limit: 120),
            capacityText: String(item.capacity),
            weightText: String(format: "%.2f", item.weight),
            endsAt: String(item.endsAt),
            startsAt: String(item.startsAt),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingInteractionSegmentViews(_ items: [RollingInteractionSegment]) -> [RollingInteractionSegmentView] {
        var views: [RollingInteractionSegmentView] = []
        for item in items {
            views.append(toRollingInteractionSegmentView(item))
        }
        return views
    }

    static func sumRollingInteractionSegmentView(_ view: RollingInteractionSegmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedCapacity) + parsedWeight + Double(parsedEndsAt)
    }
}
