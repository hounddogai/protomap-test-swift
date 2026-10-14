import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a default follow up variance.
    final class DefaultFollowUpVarianceView {
        var codeText: String
        var label: String
        var category: String
        var quantityText: String
        var version: String
        var dosageMg: String
        var channelText: String
        var approved: String
        var unitText: String
        var maximum: String
        var contactEmailText: String
        var statusLabel: String

        init(codeText: String, label: String, category: String, quantityText: String, version: String, dosageMg: String, channelText: String, approved: String, unitText: String, maximum: String, contactEmailText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.category = category
            self.quantityText = quantityText
            self.version = version
            self.dosageMg = dosageMg
            self.channelText = channelText
            self.approved = approved
            self.unitText = unitText
            self.maximum = maximum
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultFollowUpVarianceView(_ item: DefaultFollowUpVariance) -> DefaultFollowUpVarianceView {
        return DefaultFollowUpVarianceView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            category: item.category,
            quantityText: String(item.quantity),
            version: String(item.version),
            dosageMg: String(format: "%.2f", item.dosageMg),
            channelText: item.channel,
            approved: "\(item.approved)",
            unitText: item.unit,
            maximum: String(format: "%.2f", item.maximum),
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultFollowUpVarianceViews(_ items: [DefaultFollowUpVariance]) -> [DefaultFollowUpVarianceView] {
        var views: [DefaultFollowUpVarianceView] = []
        for item in items {
            views.append(toDefaultFollowUpVarianceView(item))
        }
        return views
    }

    static func sumDefaultFollowUpVarianceView(_ view: DefaultFollowUpVarianceView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedQuantity) + Double(parsedVersion) + parsedDosageMg
    }
}
