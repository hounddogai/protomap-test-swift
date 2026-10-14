import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning preference.
    final class CleaningPreferenceView {
        var code: String
        var nameText: String
        var label: String
        var marginText: String
        var countryText: String
        var source: String
        var segment: String
        var channel: String
        var ceiling: String
        var copay: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, nameText: String, label: String, marginText: String, countryText: String, source: String, segment: String, channel: String, ceiling: String, copay: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.label = label
            self.marginText = marginText
            self.countryText = countryText
            self.source = source
            self.segment = segment
            self.channel = channel
            self.ceiling = ceiling
            self.copay = copay
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningPreferenceView(_ item: CleaningPreference) -> CleaningPreferenceView {
        return CleaningPreferenceView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 64),
            marginText: String(format: "%.2f", item.margin),
            countryText: Kit.Text.truncate(item.country, limit: 80),
            source: item.source,
            segment: item.segment,
            channel: item.channel,
            ceiling: String(format: "%.2f", item.ceiling),
            copay: String(format: "%.2f", item.copay),
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningPreferenceViews(_ items: [CleaningPreference]) -> [CleaningPreferenceView] {
        var views: [CleaningPreferenceView] = []
        for item in items {
            views.append(toCleaningPreferenceView(item))
        }
        return views
    }

    static func sumCleaningPreferenceView(_ view: CleaningPreferenceView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedMargin + parsedCeiling + parsedCopay
    }
}
