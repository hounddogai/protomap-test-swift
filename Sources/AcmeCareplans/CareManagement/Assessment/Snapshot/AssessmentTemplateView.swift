import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment template.
    final class AssessmentTemplateView {
        var codeText: String
        var name: String
        var payer: String
        var facilityText: String
        var externalRefText: String
        var encounterIDText: String
        var limit: String
        var label: String
        var ward: String
        var statusLabel: String

        init(codeText: String, name: String, payer: String, facilityText: String, externalRefText: String, encounterIDText: String, limit: String, label: String, ward: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.payer = payer
            self.facilityText = facilityText
            self.externalRefText = externalRefText
            self.encounterIDText = encounterIDText
            self.limit = limit
            self.label = label
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentTemplateView(_ item: AssessmentTemplate) -> AssessmentTemplateView {
        return AssessmentTemplateView(
            codeText: item.code,
            name: item.name,
            payer: item.payer,
            facilityText: item.facility,
            externalRefText: item.externalRef,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 40),
            limit: String(item.limit),
            label: item.label,
            ward: Kit.Text.truncate(item.ward, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentTemplateViews(_ items: [AssessmentTemplate]) -> [AssessmentTemplateView] {
        var views: [AssessmentTemplateView] = []
        for item in items {
            views.append(toAssessmentTemplateView(item))
        }
        return views
    }

    static func sumAssessmentTemplateView(_ view: AssessmentTemplateView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
