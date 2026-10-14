import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form milestone.
    final class ConsentFormMilestoneView {
        var code: String
        var name: String
        var ownerID: String
        var unitText: String
        var payerText: String
        var minimumText: String
        var visible: String
        var durationMinutes: String
        var ward: String
        var activeText: String
        var statusLabel: String

        init(code: String, name: String, ownerID: String, unitText: String, payerText: String, minimumText: String, visible: String, durationMinutes: String, ward: String, activeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.unitText = unitText
            self.payerText = payerText
            self.minimumText = minimumText
            self.visible = visible
            self.durationMinutes = durationMinutes
            self.ward = ward
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormMilestoneView(_ item: ConsentFormMilestone) -> ConsentFormMilestoneView {
        return ConsentFormMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 80),
            ownerID: item.ownerID,
            unitText: item.unit,
            payerText: item.payer,
            minimumText: String(format: "%.2f", item.minimum),
            visible: "\(item.visible)",
            durationMinutes: String(item.durationMinutes),
            ward: item.ward,
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormMilestoneViews(_ items: [ConsentFormMilestone]) -> [ConsentFormMilestoneView] {
        var views: [ConsentFormMilestoneView] = []
        for item in items {
            views.append(toConsentFormMilestoneView(item))
        }
        return views
    }

    static func sumConsentFormMilestoneView(_ view: ConsentFormMilestoneView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMinimum + Double(parsedDurationMinutes)
    }
}
