import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary interaction template.
    final class PrimaryInteractionTemplateView {
        var code: String
        var labelText: String
        var rateText: String
        var countryText: String
        var ratio: String
        var timezoneText: String
        var version: String
        var wardText: String
        var minimum: String
        var notes: String
        var statusLabel: String

        init(code: String, labelText: String, rateText: String, countryText: String, ratio: String, timezoneText: String, version: String, wardText: String, minimum: String, notes: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.rateText = rateText
            self.countryText = countryText
            self.ratio = ratio
            self.timezoneText = timezoneText
            self.version = version
            self.wardText = wardText
            self.minimum = minimum
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryInteractionTemplateView(_ item: PrimaryInteractionTemplate) -> PrimaryInteractionTemplateView {
        return PrimaryInteractionTemplateView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            rateText: String(format: "%.2f", item.rate),
            countryText: item.country,
            ratio: String(format: "%.2f", item.ratio),
            timezoneText: item.timezone,
            version: String(item.version),
            wardText: item.ward,
            minimum: String(format: "%.2f", item.minimum),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryInteractionTemplateViews(_ items: [PrimaryInteractionTemplate]) -> [PrimaryInteractionTemplateView] {
        var views: [PrimaryInteractionTemplateView] = []
        for item in items {
            views.append(toPrimaryInteractionTemplateView(item))
        }
        return views
    }

    static func sumPrimaryInteractionTemplateView(_ view: PrimaryInteractionTemplateView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedRate + parsedRatio + Double(parsedVersion)
    }
}
