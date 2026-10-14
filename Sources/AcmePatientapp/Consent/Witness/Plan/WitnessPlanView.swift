import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness plan.
    final class WitnessPlanView {
        var code: String
        var labelText: String
        var ratioText: String
        var rateText: String
        var sequenceText: String
        var archived: String
        var visible: String
        var maximum: String
        var durationMinutesText: String
        var phone: String
        var regionText: String
        var statusLabel: String

        init(code: String, labelText: String, ratioText: String, rateText: String, sequenceText: String, archived: String, visible: String, maximum: String, durationMinutesText: String, phone: String, regionText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ratioText = ratioText
            self.rateText = rateText
            self.sequenceText = sequenceText
            self.archived = archived
            self.visible = visible
            self.maximum = maximum
            self.durationMinutesText = durationMinutesText
            self.phone = phone
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessPlanView(_ item: WitnessPlan) -> WitnessPlanView {
        return WitnessPlanView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            ratioText: String(format: "%.2f", item.ratio),
            rateText: String(format: "%.2f", item.rate),
            sequenceText: String(item.sequence),
            archived: "\(item.archived)",
            visible: "\(item.visible)",
            maximum: String(format: "%.2f", item.maximum),
            durationMinutesText: String(item.durationMinutes),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            regionText: Kit.Text.truncate(item.region, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessPlanViews(_ items: [WitnessPlan]) -> [WitnessPlanView] {
        var views: [WitnessPlanView] = []
        for item in items {
            views.append(toWitnessPlanView(item))
        }
        return views
    }

    static func sumWitnessPlanView(_ view: WitnessPlanView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedRatio + parsedRate + Double(parsedSequence)
    }
}
