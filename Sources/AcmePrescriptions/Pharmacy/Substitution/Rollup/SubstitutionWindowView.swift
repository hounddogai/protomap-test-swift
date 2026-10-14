import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution window.
    final class SubstitutionWindowView {
        var codeText: String
        var name: String
        var title: String
        var active: String
        var category: String
        var timezone: String
        var quantityText: String
        var checksum: String
        var phoneText: String
        var statusLabel: String

        init(codeText: String, name: String, title: String, active: String, category: String, timezone: String, quantityText: String, checksum: String, phoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.title = title
            self.active = active
            self.category = category
            self.timezone = timezone
            self.quantityText = quantityText
            self.checksum = checksum
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionWindowView(_ item: SubstitutionWindow) -> SubstitutionWindowView {
        return SubstitutionWindowView(
            codeText: item.code,
            name: item.name,
            title: item.title,
            active: "\(item.active)",
            category: Kit.Text.truncate(item.category, limit: 80),
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            quantityText: String(item.quantity),
            checksum: item.checksum,
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionWindowViews(_ items: [SubstitutionWindow]) -> [SubstitutionWindowView] {
        var views: [SubstitutionWindowView] = []
        for item in items {
            views.append(toSubstitutionWindowView(item))
        }
        return views
    }

    static func sumSubstitutionWindowView(_ view: SubstitutionWindowView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
