import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel window.
    final class PanelWindowView {
        var code: String
        var nameText: String
        var ceilingText: String
        var contactEmail: String
        var revisionText: String
        var currencyText: String
        var statusLabel: String

        init(code: String, nameText: String, ceilingText: String, contactEmail: String, revisionText: String, currencyText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ceilingText = ceilingText
            self.contactEmail = contactEmail
            self.revisionText = revisionText
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toPanelWindowView(_ item: PanelWindow) -> PanelWindowView {
        return PanelWindowView(
            code: item.code,
            nameText: item.name,
            ceilingText: String(format: "%.2f", item.ceiling),
            contactEmail: item.contactEmail,
            revisionText: String(item.revision),
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelWindowViews(_ items: [PanelWindow]) -> [PanelWindowView] {
        var views: [PanelWindowView] = []
        for item in items {
            views.append(toPanelWindowView(item))
        }
        return views
    }

    static func sumPanelWindowView(_ view: PanelWindowView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedCeiling + Double(parsedRevision)
    }
}
