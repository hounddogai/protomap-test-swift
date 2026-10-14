import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense group.
    final class DispenseGroupView {
        var codeText: String
        var name: String
        var reviewerText: String
        var visitMinutesText: String
        var clinicianID: String
        var statusLabel: String

        init(codeText: String, name: String, reviewerText: String, visitMinutesText: String, clinicianID: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.reviewerText = reviewerText
            self.visitMinutesText = visitMinutesText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseGroupView(_ item: DispenseGroup) -> DispenseGroupView {
        return DispenseGroupView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 40),
            visitMinutesText: String(item.visitMinutes),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseGroupViews(_ items: [DispenseGroup]) -> [DispenseGroupView] {
        var views: [DispenseGroupView] = []
        for item in items {
            views.append(toDispenseGroupView(item))
        }
        return views
    }

    static func sumDispenseGroupView(_ view: DispenseGroupView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
