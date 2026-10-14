import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled alert template.
    final class ScheduledAlertTemplateView {
        var code: String
        var title: String
        var facility: String
        var activeText: String
        var marginText: String
        var endsAtText: String
        var label: String
        var diagnosisCodeText: String
        var refills: String
        var floorValue: String
        var statusLabel: String

        init(code: String, title: String, facility: String, activeText: String, marginText: String, endsAtText: String, label: String, diagnosisCodeText: String, refills: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.facility = facility
            self.activeText = activeText
            self.marginText = marginText
            self.endsAtText = endsAtText
            self.label = label
            self.diagnosisCodeText = diagnosisCodeText
            self.refills = refills
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAlertTemplateView(_ item: ScheduledAlertTemplate) -> ScheduledAlertTemplateView {
        return ScheduledAlertTemplateView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            facility: item.facility,
            activeText: "\(item.active)",
            marginText: String(format: "%.2f", item.margin),
            endsAtText: String(item.endsAt),
            label: item.label,
            diagnosisCodeText: item.diagnosisCode,
            refills: String(item.refills),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAlertTemplateViews(_ items: [ScheduledAlertTemplate]) -> [ScheduledAlertTemplateView] {
        var views: [ScheduledAlertTemplateView] = []
        for item in items {
            views.append(toScheduledAlertTemplateView(item))
        }
        return views
    }

    static func sumScheduledAlertTemplateView(_ view: ScheduledAlertTemplateView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedMargin + Double(parsedEndsAt) + Double(parsedRefills)
    }
}
