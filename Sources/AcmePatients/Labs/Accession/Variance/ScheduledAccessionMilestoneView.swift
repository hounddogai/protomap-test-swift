import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled accession milestone.
    final class ScheduledAccessionMilestoneView {
        var codeText: String
        var label: String
        var ward: String
        var maximum: String
        var endsAt: String
        var phone: String
        var segment: String
        var statusLabel: String

        init(codeText: String, label: String, ward: String, maximum: String, endsAt: String, phone: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ward = ward
            self.maximum = maximum
            self.endsAt = endsAt
            self.phone = phone
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAccessionMilestoneView(_ item: ScheduledAccessionMilestone) -> ScheduledAccessionMilestoneView {
        return ScheduledAccessionMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            ward: item.ward,
            maximum: String(format: "%.2f", item.maximum),
            endsAt: String(item.endsAt),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            segment: Kit.Text.truncate(item.segment, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAccessionMilestoneViews(_ items: [ScheduledAccessionMilestone]) -> [ScheduledAccessionMilestoneView] {
        var views: [ScheduledAccessionMilestoneView] = []
        for item in items {
            views.append(toScheduledAccessionMilestoneView(item))
        }
        return views
    }

    static func sumScheduledAccessionMilestoneView(_ view: ScheduledAccessionMilestoneView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMaximum + Double(parsedEndsAt)
    }
}
