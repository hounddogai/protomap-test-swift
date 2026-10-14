import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement baseline.
    final class StatementBaselineView {
        var code: String
        var title: String
        var nameText: String
        var specialty: String
        var ownerID: String
        var ratio: String
        var descriptionText: String
        var weightText: String
        var statusLabel: String

        init(code: String, title: String, nameText: String, specialty: String, ownerID: String, ratio: String, descriptionText: String, weightText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.nameText = nameText
            self.specialty = specialty
            self.ownerID = ownerID
            self.ratio = ratio
            self.descriptionText = descriptionText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toStatementBaselineView(_ item: StatementBaseline) -> StatementBaselineView {
        return StatementBaselineView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 80),
            nameText: item.name,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            ownerID: item.ownerID,
            ratio: String(format: "%.2f", item.ratio),
            descriptionText: item.description,
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementBaselineViews(_ items: [StatementBaseline]) -> [StatementBaselineView] {
        var views: [StatementBaselineView] = []
        for item in items {
            views.append(toStatementBaselineView(item))
        }
        return views
    }

    static func sumStatementBaselineView(_ view: StatementBaselineView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedRatio + parsedWeight
    }
}
