import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan assignment.
    final class AcuityPlanAssignmentView {
        var codeText: String
        var label: String
        var country: String
        var attempts: String
        var priorityText: String
        var rate: String
        var ownerID: String
        var ratio: String
        var retries: String
        var windowDays: String
        var currencyText: String
        var statusLabel: String

        init(codeText: String, label: String, country: String, attempts: String, priorityText: String, rate: String, ownerID: String, ratio: String, retries: String, windowDays: String, currencyText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.country = country
            self.attempts = attempts
            self.priorityText = priorityText
            self.rate = rate
            self.ownerID = ownerID
            self.ratio = ratio
            self.retries = retries
            self.windowDays = windowDays
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanAssignmentView(_ item: AcuityPlanAssignment) -> AcuityPlanAssignmentView {
        return AcuityPlanAssignmentView(
            codeText: item.code,
            label: item.label,
            country: item.country,
            attempts: String(item.attempts),
            priorityText: String(item.priority),
            rate: String(format: "%.2f", item.rate),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            retries: String(item.retries),
            windowDays: String(item.windowDays),
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanAssignmentViews(_ items: [AcuityPlanAssignment]) -> [AcuityPlanAssignmentView] {
        var views: [AcuityPlanAssignmentView] = []
        for item in items {
            views.append(toAcuityPlanAssignmentView(item))
        }
        return views
    }

    static func sumAcuityPlanAssignmentView(_ view: AcuityPlanAssignmentView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedAttempts) + Double(parsedPriority) + parsedRate
    }
}
