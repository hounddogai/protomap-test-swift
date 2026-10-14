import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary handoff agreement.
    final class PrimaryHandoffAgreementView {
        var code: String
        var titleText: String
        var discountText: String
        var expiresAt: String
        var visible: String
        var priority: String
        var limit: String
        var channel: String
        var notes: String
        var countryText: String
        var statusLabel: String

        init(code: String, titleText: String, discountText: String, expiresAt: String, visible: String, priority: String, limit: String, channel: String, notes: String, countryText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.discountText = discountText
            self.expiresAt = expiresAt
            self.visible = visible
            self.priority = priority
            self.limit = limit
            self.channel = channel
            self.notes = notes
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryHandoffAgreementView(_ item: PrimaryHandoffAgreement) -> PrimaryHandoffAgreementView {
        return PrimaryHandoffAgreementView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            discountText: String(format: "%.2f", item.discount),
            expiresAt: String(item.expiresAt),
            visible: "\(item.visible)",
            priority: String(item.priority),
            limit: String(item.limit),
            channel: item.channel,
            notes: item.notes,
            countryText: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryHandoffAgreementViews(_ items: [PrimaryHandoffAgreement]) -> [PrimaryHandoffAgreementView] {
        var views: [PrimaryHandoffAgreementView] = []
        for item in items {
            views.append(toPrimaryHandoffAgreementView(item))
        }
        return views
    }

    static func sumPrimaryHandoffAgreementView(_ view: PrimaryHandoffAgreementView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDiscount + Double(parsedExpiresAt) + Double(parsedPriority)
    }
}
