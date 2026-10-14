import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling cleaning assignment.
    final class RollingCleaningAssignmentView {
        var codeText: String
        var labelText: String
        var externalRef: String
        var limitText: String
        var patientRef: String
        var budget: String
        var channel: String
        var ownerID: String
        var rate: String
        var wardText: String
        var statusLabel: String

        init(codeText: String, labelText: String, externalRef: String, limitText: String, patientRef: String, budget: String, channel: String, ownerID: String, rate: String, wardText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.externalRef = externalRef
            self.limitText = limitText
            self.patientRef = patientRef
            self.budget = budget
            self.channel = channel
            self.ownerID = ownerID
            self.rate = rate
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCleaningAssignmentView(_ item: RollingCleaningAssignment) -> RollingCleaningAssignmentView {
        return RollingCleaningAssignmentView(
            codeText: item.code,
            labelText: item.label,
            externalRef: item.externalRef,
            limitText: String(item.limit),
            patientRef: item.patientRef,
            budget: String(format: "%.2f", item.budget),
            channel: item.channel,
            ownerID: item.ownerID,
            rate: String(format: "%.2f", item.rate),
            wardText: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCleaningAssignmentViews(_ items: [RollingCleaningAssignment]) -> [RollingCleaningAssignmentView] {
        var views: [RollingCleaningAssignmentView] = []
        for item in items {
            views.append(toRollingCleaningAssignmentView(item))
        }
        return views
    }

    static func sumRollingCleaningAssignmentView(_ view: RollingCleaningAssignmentView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedLimit) + parsedBudget + parsedRate
    }
}
