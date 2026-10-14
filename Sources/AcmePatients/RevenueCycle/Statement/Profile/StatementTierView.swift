import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement tier.
    final class StatementTierView {
        var code: String
        var nameText: String
        var phone: String
        var weight: String
        var title: String
        var specialty: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, nameText: String, phone: String, weight: String, title: String, specialty: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.phone = phone
            self.weight = weight
            self.title = title
            self.specialty = specialty
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toStatementTierView(_ item: StatementTier) -> StatementTierView {
        return StatementTierView(
            code: item.code,
            nameText: item.name,
            phone: Kit.Text.truncate(item.phone, limit: 64),
            weight: String(format: "%.2f", item.weight),
            title: item.title,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementTierViews(_ items: [StatementTier]) -> [StatementTierView] {
        var views: [StatementTierView] = []
        for item in items {
            views.append(toStatementTierView(item))
        }
        return views
    }

    static func sumStatementTierView(_ view: StatementTierView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
