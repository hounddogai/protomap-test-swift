import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime batch.
    final class OvertimeBatchView {
        var code: String
        var name: String
        var ceiling: String
        var descriptionText: String
        var contactEmail: String
        var category: String
        var specialty: String
        var discount: String
        var phone: String
        var labelText: String
        var revision: String
        var statusLabel: String

        init(code: String, name: String, ceiling: String, descriptionText: String, contactEmail: String, category: String, specialty: String, discount: String, phone: String, labelText: String, revision: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.descriptionText = descriptionText
            self.contactEmail = contactEmail
            self.category = category
            self.specialty = specialty
            self.discount = discount
            self.phone = phone
            self.labelText = labelText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeBatchView(_ item: OvertimeBatch) -> OvertimeBatchView {
        return OvertimeBatchView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            contactEmail: item.contactEmail,
            category: item.category,
            specialty: item.specialty,
            discount: String(format: "%.2f", item.discount),
            phone: item.phone,
            labelText: item.label,
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeBatchViews(_ items: [OvertimeBatch]) -> [OvertimeBatchView] {
        var views: [OvertimeBatchView] = []
        for item in items {
            views.append(toOvertimeBatchView(item))
        }
        return views
    }

    static func sumOvertimeBatchView(_ view: OvertimeBatchView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedCeiling + parsedDiscount + Double(parsedRevision)
    }
}
