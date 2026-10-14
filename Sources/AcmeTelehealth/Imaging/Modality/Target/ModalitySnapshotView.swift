import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality snapshot.
    final class ModalitySnapshotView {
        var codeText: String
        var titleText: String
        var budgetText: String
        var cost: String
        var durationMinutesText: String
        var statusLabel: String

        init(codeText: String, titleText: String, budgetText: String, cost: String, durationMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.budgetText = budgetText
            self.cost = cost
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toModalitySnapshotView(_ item: ModalitySnapshot) -> ModalitySnapshotView {
        return ModalitySnapshotView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            budgetText: String(format: "%.2f", item.budget),
            cost: String(format: "%.2f", item.cost),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalitySnapshotViews(_ items: [ModalitySnapshot]) -> [ModalitySnapshotView] {
        var views: [ModalitySnapshotView] = []
        for item in items {
            views.append(toModalitySnapshotView(item))
        }
        return views
    }

    static func sumModalitySnapshotView(_ view: ModalitySnapshotView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedBudget + parsedCost + Double(parsedDurationMinutes)
    }
}
