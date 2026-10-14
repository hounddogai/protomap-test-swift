import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution group.
    final class SubstitutionGroupView {
        var codeText: String
        var name: String
        var limit: String
        var capacity: String
        var active: String
        var discount: String
        var externalRef: String
        var startsAt: String
        var locale: String
        var statusLabel: String

        init(codeText: String, name: String, limit: String, capacity: String, active: String, discount: String, externalRef: String, startsAt: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.limit = limit
            self.capacity = capacity
            self.active = active
            self.discount = discount
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionGroupView(_ item: SubstitutionGroup) -> SubstitutionGroupView {
        return SubstitutionGroupView(
            codeText: item.code,
            name: item.name,
            limit: String(item.limit),
            capacity: String(item.capacity),
            active: "\(item.active)",
            discount: String(format: "%.2f", item.discount),
            externalRef: item.externalRef,
            startsAt: String(item.startsAt),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionGroupViews(_ items: [SubstitutionGroup]) -> [SubstitutionGroupView] {
        var views: [SubstitutionGroupView] = []
        for item in items {
            views.append(toSubstitutionGroupView(item))
        }
        return views
    }

    static func sumSubstitutionGroupView(_ view: SubstitutionGroupView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedLimit) + Double(parsedCapacity) + parsedDiscount
    }
}
