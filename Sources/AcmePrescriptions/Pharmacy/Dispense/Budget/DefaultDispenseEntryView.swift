import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default dispense entry.
    final class DefaultDispenseEntryView {
        var codeText: String
        var name: String
        var ratio: String
        var updatedAtText: String
        var archived: String
        var statusLabel: String

        init(codeText: String, name: String, ratio: String, updatedAtText: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ratio = ratio
            self.updatedAtText = updatedAtText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultDispenseEntryView(_ item: DefaultDispenseEntry) -> DefaultDispenseEntryView {
        return DefaultDispenseEntryView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            updatedAtText: String(item.updatedAt),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultDispenseEntryViews(_ items: [DefaultDispenseEntry]) -> [DefaultDispenseEntryView] {
        var views: [DefaultDispenseEntryView] = []
        for item in items {
            views.append(toDefaultDispenseEntryView(item))
        }
        return views
    }

    static func sumDefaultDispenseEntryView(_ view: DefaultDispenseEntryView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedRatio + Double(parsedUpdatedAt)
    }
}
