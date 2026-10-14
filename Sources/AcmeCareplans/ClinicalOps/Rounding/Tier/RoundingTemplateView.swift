import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding template.
    final class RoundingTemplateView {
        var codeText: String
        var name: String
        var patientRef: String
        var acuity: String
        var minimum: String
        var locale: String
        var channelText: String
        var margin: String
        var statusLabel: String

        init(codeText: String, name: String, patientRef: String, acuity: String, minimum: String, locale: String, channelText: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.patientRef = patientRef
            self.acuity = acuity
            self.minimum = minimum
            self.locale = locale
            self.channelText = channelText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingTemplateView(_ item: RoundingTemplate) -> RoundingTemplateView {
        return RoundingTemplateView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            patientRef: item.patientRef,
            acuity: String(item.acuity),
            minimum: String(format: "%.2f", item.minimum),
            locale: item.locale,
            channelText: item.channel,
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingTemplateViews(_ items: [RoundingTemplate]) -> [RoundingTemplateView] {
        var views: [RoundingTemplateView] = []
        for item in items {
            views.append(toRoundingTemplateView(item))
        }
        return views
    }

    static func sumRoundingTemplateView(_ view: RoundingTemplateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAcuity) + parsedMinimum + parsedMargin
    }
}
