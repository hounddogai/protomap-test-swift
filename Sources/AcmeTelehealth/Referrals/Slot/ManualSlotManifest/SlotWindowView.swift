import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot window.
    final class SlotWindowView {
        var code: String
        var label: String
        var thresholdText: String
        var externalRef: String
        var title: String
        var specialty: String
        var visitMinutesText: String
        var durationMinutes: String
        var procedureCodeText: String
        var statusLabel: String

        init(code: String, label: String, thresholdText: String, externalRef: String, title: String, specialty: String, visitMinutesText: String, durationMinutes: String, procedureCodeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.thresholdText = thresholdText
            self.externalRef = externalRef
            self.title = title
            self.specialty = specialty
            self.visitMinutesText = visitMinutesText
            self.durationMinutes = durationMinutes
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotWindowView(_ item: SlotWindow) -> SlotWindowView {
        return SlotWindowView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            thresholdText: String(format: "%.2f", item.threshold),
            externalRef: item.externalRef,
            title: item.title,
            specialty: item.specialty,
            visitMinutesText: String(item.visitMinutes),
            durationMinutes: String(item.durationMinutes),
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotWindowViews(_ items: [SlotWindow]) -> [SlotWindowView] {
        var views: [SlotWindowView] = []
        for item in items {
            views.append(toSlotWindowView(item))
        }
        return views
    }

    static func sumSlotWindowView(_ view: SlotWindowView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedThreshold + Double(parsedVisitMinutes) + Double(parsedDurationMinutes)
    }
}
