import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary consent form entry.
    final class PrimaryConsentFormEntryView {
        var code: String
        var nameText: String
        var bed: String
        var label: String
        var contactEmail: String
        var maximumText: String
        var discount: String
        var limit: String
        var visible: String
        var allergy: String
        var statusLabel: String

        init(code: String, nameText: String, bed: String, label: String, contactEmail: String, maximumText: String, discount: String, limit: String, visible: String, allergy: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.bed = bed
            self.label = label
            self.contactEmail = contactEmail
            self.maximumText = maximumText
            self.discount = discount
            self.limit = limit
            self.visible = visible
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryConsentFormEntryView(_ item: PrimaryConsentFormEntry) -> PrimaryConsentFormEntryView {
        return PrimaryConsentFormEntryView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            label: item.label,
            contactEmail: item.contactEmail,
            maximumText: String(format: "%.2f", item.maximum),
            discount: String(format: "%.2f", item.discount),
            limit: String(item.limit),
            visible: "\(item.visible)",
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryConsentFormEntryViews(_ items: [PrimaryConsentFormEntry]) -> [PrimaryConsentFormEntryView] {
        var views: [PrimaryConsentFormEntryView] = []
        for item in items {
            views.append(toPrimaryConsentFormEntryView(item))
        }
        return views
    }

    static func sumPrimaryConsentFormEntryView(_ view: PrimaryConsentFormEntryView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMaximum + parsedDiscount + Double(parsedLimit)
    }
}
