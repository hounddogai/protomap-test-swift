import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen milestone.
    final class SpecimenMilestoneView {
        var code: String
        var labelText: String
        var facilityText: String
        var retries: String
        var timezoneText: String
        var description: String
        var statusLabel: String

        init(code: String, labelText: String, facilityText: String, retries: String, timezoneText: String, description: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.facilityText = facilityText
            self.retries = retries
            self.timezoneText = timezoneText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenMilestoneView(_ item: SpecimenMilestone) -> SpecimenMilestoneView {
        return SpecimenMilestoneView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            facilityText: item.facility,
            retries: String(item.retries),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 40),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenMilestoneViews(_ items: [SpecimenMilestone]) -> [SpecimenMilestoneView] {
        var views: [SpecimenMilestoneView] = []
        for item in items {
            views.append(toSpecimenMilestoneView(item))
        }
        return views
    }

    static func sumSpecimenMilestoneView(_ view: SpecimenMilestoneView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
