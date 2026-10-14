import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure exception.
    final class DisclosureExceptionView {
        var code: String
        var name: String
        var ceilingText: String
        var contactEmailText: String
        var facility: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, ceilingText: String, contactEmailText: String, facility: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceilingText = ceilingText
            self.contactEmailText = contactEmailText
            self.facility = facility
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureExceptionView(_ item: DisclosureException) -> DisclosureExceptionView {
        return DisclosureExceptionView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            ceilingText: String(format: "%.2f", item.ceiling),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 120),
            facility: item.facility,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureExceptionViews(_ items: [DisclosureException]) -> [DisclosureExceptionView] {
        var views: [DisclosureExceptionView] = []
        for item in items {
            views.append(toDisclosureExceptionView(item))
        }
        return views
    }

    static func sumDisclosureExceptionView(_ view: DisclosureExceptionView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCeiling + Double(parsedBatchSize)
    }
}
