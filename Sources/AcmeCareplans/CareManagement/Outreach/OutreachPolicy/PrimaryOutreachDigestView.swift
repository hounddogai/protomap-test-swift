import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a primary outreach digest.
    final class PrimaryOutreachDigestView {
        var codeText: String
        var title: String
        var visible: String
        var ward: String
        var currency: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, title: String, visible: String, ward: String, currency: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.visible = visible
            self.ward = ward
            self.currency = currency
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryOutreachDigestView(_ item: PrimaryOutreachDigest) -> PrimaryOutreachDigestView {
        return PrimaryOutreachDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            visible: "\(item.visible)",
            ward: Kit.Text.truncate(item.ward, limit: 120),
            currency: item.currency,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryOutreachDigestViews(_ items: [PrimaryOutreachDigest]) -> [PrimaryOutreachDigestView] {
        var views: [PrimaryOutreachDigestView] = []
        for item in items {
            views.append(toPrimaryOutreachDigestView(item))
        }
        return views
    }

    static func sumPrimaryOutreachDigestView(_ view: PrimaryOutreachDigestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
