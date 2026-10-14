import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result policy.
    final class ResultPolicyView {
        var codeText: String
        var labelText: String
        var sequence: String
        var visitMinutesText: String
        var contactEmail: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, labelText: String, sequence: String, visitMinutesText: String, contactEmail: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.sequence = sequence
            self.visitMinutesText = visitMinutesText
            self.contactEmail = contactEmail
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toResultPolicyView(_ item: ResultPolicy) -> ResultPolicyView {
        return ResultPolicyView(
            codeText: item.code,
            labelText: item.label,
            sequence: String(item.sequence),
            visitMinutesText: String(item.visitMinutes),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultPolicyViews(_ items: [ResultPolicy]) -> [ResultPolicyView] {
        var views: [ResultPolicyView] = []
        for item in items {
            views.append(toResultPolicyView(item))
        }
        return views
    }

    static func sumResultPolicyView(_ view: ResultPolicyView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedSequence) + Double(parsedVisitMinutes) + Double(parsedWindowDays)
    }
}
