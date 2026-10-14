import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global revocation group.
    final class GlobalRevocationGroupView {
        var code: String
        var titleText: String
        var createdAt: String
        var active: String
        var limitText: String
        var pinned: String
        var unit: String
        var discount: String
        var bed: String
        var category: String
        var statusLabel: String

        init(code: String, titleText: String, createdAt: String, active: String, limitText: String, pinned: String, unit: String, discount: String, bed: String, category: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.createdAt = createdAt
            self.active = active
            self.limitText = limitText
            self.pinned = pinned
            self.unit = unit
            self.discount = discount
            self.bed = bed
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalRevocationGroupView(_ item: GlobalRevocationGroup) -> GlobalRevocationGroupView {
        return GlobalRevocationGroupView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            createdAt: String(item.createdAt),
            active: "\(item.active)",
            limitText: String(item.limit),
            pinned: "\(item.pinned)",
            unit: Kit.Text.truncate(item.unit, limit: 64),
            discount: String(format: "%.2f", item.discount),
            bed: item.bed,
            category: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalRevocationGroupViews(_ items: [GlobalRevocationGroup]) -> [GlobalRevocationGroupView] {
        var views: [GlobalRevocationGroupView] = []
        for item in items {
            views.append(toGlobalRevocationGroupView(item))
        }
        return views
    }

    static func sumGlobalRevocationGroupView(_ view: GlobalRevocationGroupView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedLimit) + parsedDiscount
    }
}
