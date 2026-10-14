import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language checkpoint.
    final class LanguageCheckpointView {
        var codeText: String
        var nameText: String
        var contactEmail: String
        var channel: String
        var costText: String
        var dosageMgText: String
        var refills: String
        var countryText: String
        var capacityText: String
        var statusLabel: String

        init(codeText: String, nameText: String, contactEmail: String, channel: String, costText: String, dosageMgText: String, refills: String, countryText: String, capacityText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.contactEmail = contactEmail
            self.channel = channel
            self.costText = costText
            self.dosageMgText = dosageMgText
            self.refills = refills
            self.countryText = countryText
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageCheckpointView(_ item: LanguageCheckpoint) -> LanguageCheckpointView {
        return LanguageCheckpointView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            contactEmail: item.contactEmail,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            costText: String(format: "%.2f", item.cost),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            refills: String(item.refills),
            countryText: Kit.Text.truncate(item.country, limit: 120),
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageCheckpointViews(_ items: [LanguageCheckpoint]) -> [LanguageCheckpointView] {
        var views: [LanguageCheckpointView] = []
        for item in items {
            views.append(toLanguageCheckpointView(item))
        }
        return views
    }

    static func sumLanguageCheckpointView(_ view: LanguageCheckpointView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedCost + parsedDosageMg + Double(parsedRefills)
    }
}
