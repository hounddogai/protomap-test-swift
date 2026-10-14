import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary accession window.
    final class PrimaryAccessionWindowView {
        var code: String
        var label: String
        var country: String
        var priority: String
        var margin: String
        var name: String
        var statusLabel: String

        init(code: String, label: String, country: String, priority: String, margin: String, name: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.country = country
            self.priority = priority
            self.margin = margin
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAccessionWindowView(_ item: PrimaryAccessionWindow) -> PrimaryAccessionWindowView {
        return PrimaryAccessionWindowView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 120),
            country: item.country,
            priority: String(item.priority),
            margin: String(format: "%.2f", item.margin),
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAccessionWindowViews(_ items: [PrimaryAccessionWindow]) -> [PrimaryAccessionWindowView] {
        var views: [PrimaryAccessionWindowView] = []
        for item in items {
            views.append(toPrimaryAccessionWindowView(item))
        }
        return views
    }

    static func sumPrimaryAccessionWindowView(_ view: PrimaryAccessionWindowView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedPriority) + parsedMargin
    }
}
