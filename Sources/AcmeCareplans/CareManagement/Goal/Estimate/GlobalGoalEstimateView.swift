import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global goal estimate.
    final class GlobalGoalEstimateView {
        var code: String
        var name: String
        var archived: String
        var sourceText: String
        var visibleText: String
        var checksum: String
        var clinicianID: String
        var amount: String
        var statusLabel: String

        init(code: String, name: String, archived: String, sourceText: String, visibleText: String, checksum: String, clinicianID: String, amount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.sourceText = sourceText
            self.visibleText = visibleText
            self.checksum = checksum
            self.clinicianID = clinicianID
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalGoalEstimateView(_ item: GlobalGoalEstimate) -> GlobalGoalEstimateView {
        return GlobalGoalEstimateView(
            code: item.code,
            name: item.name,
            archived: "\(item.archived)",
            sourceText: item.source,
            visibleText: "\(item.visible)",
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            clinicianID: item.clinicianID,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalGoalEstimateViews(_ items: [GlobalGoalEstimate]) -> [GlobalGoalEstimateView] {
        var views: [GlobalGoalEstimateView] = []
        for item in items {
            views.append(toGlobalGoalEstimateView(item))
        }
        return views
    }

    static func sumGlobalGoalEstimateView(_ view: GlobalGoalEstimateView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
