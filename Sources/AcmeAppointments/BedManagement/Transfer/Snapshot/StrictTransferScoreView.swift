import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict transfer score.
    final class StrictTransferScoreView {
        var code: String
        var labelText: String
        var budgetText: String
        var clinicianID: String
        var copayText: String
        var statusLabel: String

        init(code: String, labelText: String, budgetText: String, clinicianID: String, copayText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.budgetText = budgetText
            self.clinicianID = clinicianID
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictTransferScoreView(_ item: StrictTransferScore) -> StrictTransferScoreView {
        return StrictTransferScoreView(
            code: item.code,
            labelText: item.label,
            budgetText: String(format: "%.2f", item.budget),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictTransferScoreViews(_ items: [StrictTransferScore]) -> [StrictTransferScoreView] {
        var views: [StrictTransferScoreView] = []
        for item in items {
            views.append(toStrictTransferScoreView(item))
        }
        return views
    }

    static func sumStrictTransferScoreView(_ view: StrictTransferScoreView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedBudget + parsedCopay
    }
}
