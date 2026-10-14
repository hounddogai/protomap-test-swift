import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual modality mapping.
    final class ManualModalityMappingView {
        var code: String
        var title: String
        var updatedAt: String
        var expiresAt: String
        var acuityText: String
        var contactEmail: String
        var externalRefText: String
        var copay: String
        var currencyText: String
        var statusLabel: String

        init(code: String, title: String, updatedAt: String, expiresAt: String, acuityText: String, contactEmail: String, externalRefText: String, copay: String, currencyText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.expiresAt = expiresAt
            self.acuityText = acuityText
            self.contactEmail = contactEmail
            self.externalRefText = externalRefText
            self.copay = copay
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toManualModalityMappingView(_ item: ManualModalityMapping) -> ManualModalityMappingView {
        return ManualModalityMappingView(
            code: item.code,
            title: item.title,
            updatedAt: String(item.updatedAt),
            expiresAt: String(item.expiresAt),
            acuityText: String(item.acuity),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            externalRefText: item.externalRef,
            copay: String(format: "%.2f", item.copay),
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualModalityMappingViews(_ items: [ManualModalityMapping]) -> [ManualModalityMappingView] {
        var views: [ManualModalityMappingView] = []
        for item in items {
            views.append(toManualModalityMappingView(item))
        }
        return views
    }

    static func sumManualModalityMappingView(_ view: ManualModalityMappingView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedExpiresAt) + Double(parsedAcuity)
    }
}
