import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict modality entry.
    final class StrictModalityEntryView {
        var code: String
        var titleText: String
        var name: String
        var createdAt: String
        var encounterID: String
        var externalRefText: String
        var revision: String
        var unit: String
        var discount: String
        var statusLabel: String

        init(code: String, titleText: String, name: String, createdAt: String, encounterID: String, externalRefText: String, revision: String, unit: String, discount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.name = name
            self.createdAt = createdAt
            self.encounterID = encounterID
            self.externalRefText = externalRefText
            self.revision = revision
            self.unit = unit
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toStrictModalityEntryView(_ item: StrictModalityEntry) -> StrictModalityEntryView {
        return StrictModalityEntryView(
            code: item.code,
            titleText: item.title,
            name: item.name,
            createdAt: String(item.createdAt),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            externalRefText: item.externalRef,
            revision: String(item.revision),
            unit: Kit.Text.truncate(item.unit, limit: 120),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictModalityEntryViews(_ items: [StrictModalityEntry]) -> [StrictModalityEntryView] {
        var views: [StrictModalityEntryView] = []
        for item in items {
            views.append(toStrictModalityEntryView(item))
        }
        return views
    }

    static func sumStrictModalityEntryView(_ view: StrictModalityEntryView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRevision) + parsedDiscount
    }
}
