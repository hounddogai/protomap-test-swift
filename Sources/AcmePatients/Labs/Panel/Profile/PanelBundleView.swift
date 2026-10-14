import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel bundle.
    final class PanelBundleView {
        var codeText: String
        var nameText: String
        var categoryText: String
        var region: String
        var locale: String
        var externalRef: String
        var budget: String
        var archivedText: String
        var notesText: String
        var endsAt: String
        var statusLabel: String

        init(codeText: String, nameText: String, categoryText: String, region: String, locale: String, externalRef: String, budget: String, archivedText: String, notesText: String, endsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.categoryText = categoryText
            self.region = region
            self.locale = locale
            self.externalRef = externalRef
            self.budget = budget
            self.archivedText = archivedText
            self.notesText = notesText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toPanelBundleView(_ item: PanelBundle) -> PanelBundleView {
        return PanelBundleView(
            codeText: item.code,
            nameText: item.name,
            categoryText: item.category,
            region: item.region,
            locale: Kit.Text.truncate(item.locale, limit: 64),
            externalRef: item.externalRef,
            budget: String(format: "%.2f", item.budget),
            archivedText: "\(item.archived)",
            notesText: item.notes,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelBundleViews(_ items: [PanelBundle]) -> [PanelBundleView] {
        var views: [PanelBundleView] = []
        for item in items {
            views.append(toPanelBundleView(item))
        }
        return views
    }

    static func sumPanelBundleView(_ view: PanelBundleView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedBudget + Double(parsedEndsAt)
    }
}
