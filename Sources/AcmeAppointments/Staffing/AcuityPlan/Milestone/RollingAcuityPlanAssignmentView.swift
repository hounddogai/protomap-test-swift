import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a rolling acuity plan assignment.
    final class RollingAcuityPlanAssignmentView {
        var code: String
        var nameText: String
        var sequence: String
        var durationMinutesText: String
        var descriptionText: String
        var threshold: String
        var label: String
        var retries: String
        var statusLabel: String

        init(code: String, nameText: String, sequence: String, durationMinutesText: String, descriptionText: String, threshold: String, label: String, retries: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.sequence = sequence
            self.durationMinutesText = durationMinutesText
            self.descriptionText = descriptionText
            self.threshold = threshold
            self.label = label
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAcuityPlanAssignmentView(_ item: RollingAcuityPlanAssignment) -> RollingAcuityPlanAssignmentView {
        return RollingAcuityPlanAssignmentView(
            code: item.code,
            nameText: item.name,
            sequence: String(item.sequence),
            durationMinutesText: String(item.durationMinutes),
            descriptionText: item.description,
            threshold: String(format: "%.2f", item.threshold),
            label: item.label,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAcuityPlanAssignmentViews(_ items: [RollingAcuityPlanAssignment]) -> [RollingAcuityPlanAssignmentView] {
        var views: [RollingAcuityPlanAssignmentView] = []
        for item in items {
            views.append(toRollingAcuityPlanAssignmentView(item))
        }
        return views
    }

    static func sumRollingAcuityPlanAssignmentView(_ view: RollingAcuityPlanAssignmentView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedSequence) + Double(parsedDurationMinutes) + parsedThreshold
    }
}
