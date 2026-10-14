import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled outreach agreement.
    final class ScheduledOutreachAgreementView {
        var code: String
        var titleText: String
        var floorValue: String
        var margin: String
        var ownerID: String
        var statusLabel: String

        init(code: String, titleText: String, floorValue: String, margin: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.floorValue = floorValue
            self.margin = margin
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledOutreachAgreementView(_ item: ScheduledOutreachAgreement) -> ScheduledOutreachAgreementView {
        return ScheduledOutreachAgreementView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            margin: String(format: "%.2f", item.margin),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledOutreachAgreementViews(_ items: [ScheduledOutreachAgreement]) -> [ScheduledOutreachAgreementView] {
        var views: [ScheduledOutreachAgreementView] = []
        for item in items {
            views.append(toScheduledOutreachAgreementView(item))
        }
        return views
    }

    static func sumScheduledOutreachAgreementView(_ view: ScheduledOutreachAgreementView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedFloorValue + parsedMargin
    }
}
