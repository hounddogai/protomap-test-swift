import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled witness milestone.
    final class ScheduledWitnessMilestoneView {
        var codeText: String
        var titleText: String
        var unitText: String
        var specialtyText: String
        var version: String
        var label: String
        var statusLabel: String

        init(codeText: String, titleText: String, unitText: String, specialtyText: String, version: String, label: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.unitText = unitText
            self.specialtyText = specialtyText
            self.version = version
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledWitnessMilestoneView(_ item: ScheduledWitnessMilestone) -> ScheduledWitnessMilestoneView {
        return ScheduledWitnessMilestoneView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            unitText: item.unit,
            specialtyText: item.specialty,
            version: String(item.version),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledWitnessMilestoneViews(_ items: [ScheduledWitnessMilestone]) -> [ScheduledWitnessMilestoneView] {
        var views: [ScheduledWitnessMilestoneView] = []
        for item in items {
            views.append(toScheduledWitnessMilestoneView(item))
        }
        return views
    }

    static func sumScheduledWitnessMilestoneView(_ view: ScheduledWitnessMilestoneView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
