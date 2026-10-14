import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual witness threshold.
    final class ManualWitnessThresholdView {
        var codeText: String
        var nameText: String
        var phone: String
        var locale: String
        var contactEmail: String
        var externalRef: String
        var startsAtText: String
        var summary: String
        var discountText: String
        var sequenceText: String
        var budget: String
        var statusLabel: String

        init(codeText: String, nameText: String, phone: String, locale: String, contactEmail: String, externalRef: String, startsAtText: String, summary: String, discountText: String, sequenceText: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.phone = phone
            self.locale = locale
            self.contactEmail = contactEmail
            self.externalRef = externalRef
            self.startsAtText = startsAtText
            self.summary = summary
            self.discountText = discountText
            self.sequenceText = sequenceText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toManualWitnessThresholdView(_ item: ManualWitnessThreshold) -> ManualWitnessThresholdView {
        return ManualWitnessThresholdView(
            codeText: item.code,
            nameText: item.name,
            phone: item.phone,
            locale: item.locale,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            externalRef: item.externalRef,
            startsAtText: String(item.startsAt),
            summary: item.summary,
            discountText: String(format: "%.2f", item.discount),
            sequenceText: String(item.sequence),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualWitnessThresholdViews(_ items: [ManualWitnessThreshold]) -> [ManualWitnessThresholdView] {
        var views: [ManualWitnessThresholdView] = []
        for item in items {
            views.append(toManualWitnessThresholdView(item))
        }
        return views
    }

    static func sumManualWitnessThresholdView(_ view: ManualWitnessThresholdView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedStartsAt) + parsedDiscount + Double(parsedSequence)
    }
}
