import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual cleaning assignment.
    final class ManualCleaningAssignmentView {
        var codeText: String
        var titleText: String
        var contactEmail: String
        var acuity: String
        var windowDays: String
        var marginText: String
        var approved: String
        var batchSize: String
        var copay: String
        var retries: String
        var limit: String
        var statusLabel: String

        init(codeText: String, titleText: String, contactEmail: String, acuity: String, windowDays: String, marginText: String, approved: String, batchSize: String, copay: String, retries: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.contactEmail = contactEmail
            self.acuity = acuity
            self.windowDays = windowDays
            self.marginText = marginText
            self.approved = approved
            self.batchSize = batchSize
            self.copay = copay
            self.retries = retries
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toManualCleaningAssignmentView(_ item: ManualCleaningAssignment) -> ManualCleaningAssignmentView {
        return ManualCleaningAssignmentView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            acuity: String(item.acuity),
            windowDays: String(item.windowDays),
            marginText: String(format: "%.2f", item.margin),
            approved: "\(item.approved)",
            batchSize: String(item.batchSize),
            copay: String(format: "%.2f", item.copay),
            retries: String(item.retries),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCleaningAssignmentViews(_ items: [ManualCleaningAssignment]) -> [ManualCleaningAssignmentView] {
        var views: [ManualCleaningAssignmentView] = []
        for item in items {
            views.append(toManualCleaningAssignmentView(item))
        }
        return views
    }

    static func sumManualCleaningAssignmentView(_ view: ManualCleaningAssignmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAcuity) + Double(parsedWindowDays) + parsedMargin
    }
}
