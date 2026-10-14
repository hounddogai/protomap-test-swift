import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual denial agreement.
    final class ManualDenialAgreementView {
        var codeText: String
        var name: String
        var endsAt: String
        var allergyText: String
        var maximumText: String
        var title: String
        var refills: String
        var updatedAt: String
        var externalRef: String
        var rateText: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, name: String, endsAt: String, allergyText: String, maximumText: String, title: String, refills: String, updatedAt: String, externalRef: String, rateText: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.endsAt = endsAt
            self.allergyText = allergyText
            self.maximumText = maximumText
            self.title = title
            self.refills = refills
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.rateText = rateText
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toManualDenialAgreementView(_ item: ManualDenialAgreement) -> ManualDenialAgreementView {
        return ManualDenialAgreementView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            endsAt: String(item.endsAt),
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            maximumText: String(format: "%.2f", item.maximum),
            title: item.title,
            refills: String(item.refills),
            updatedAt: String(item.updatedAt),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            rateText: String(format: "%.2f", item.rate),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDenialAgreementViews(_ items: [ManualDenialAgreement]) -> [ManualDenialAgreementView] {
        var views: [ManualDenialAgreementView] = []
        for item in items {
            views.append(toManualDenialAgreementView(item))
        }
        return views
    }

    static func sumManualDenialAgreementView(_ view: ManualDenialAgreementView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedEndsAt) + parsedMaximum + Double(parsedRefills)
    }
}
