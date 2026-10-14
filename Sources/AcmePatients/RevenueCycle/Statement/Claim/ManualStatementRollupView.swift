import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual statement rollup.
    final class ManualStatementRollupView {
        var code: String
        var titleText: String
        var createdAtText: String
        var amountText: String
        var label: String
        var specialty: String
        var archivedText: String
        var durationMinutes: String
        var copayText: String
        var statusLabel: String

        init(code: String, titleText: String, createdAtText: String, amountText: String, label: String, specialty: String, archivedText: String, durationMinutes: String, copayText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.createdAtText = createdAtText
            self.amountText = amountText
            self.label = label
            self.specialty = specialty
            self.archivedText = archivedText
            self.durationMinutes = durationMinutes
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toManualStatementRollupView(_ item: ManualStatementRollup) -> ManualStatementRollupView {
        return ManualStatementRollupView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            createdAtText: String(item.createdAt),
            amountText: String(format: "%.2f", item.amount),
            label: Kit.Text.truncate(item.label, limit: 64),
            specialty: item.specialty,
            archivedText: "\(item.archived)",
            durationMinutes: String(item.durationMinutes),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualStatementRollupViews(_ items: [ManualStatementRollup]) -> [ManualStatementRollupView] {
        var views: [ManualStatementRollupView] = []
        for item in items {
            views.append(toManualStatementRollupView(item))
        }
        return views
    }

    static func sumManualStatementRollupView(_ view: ManualStatementRollupView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedCreatedAt) + parsedAmount + Double(parsedDurationMinutes)
    }
}
