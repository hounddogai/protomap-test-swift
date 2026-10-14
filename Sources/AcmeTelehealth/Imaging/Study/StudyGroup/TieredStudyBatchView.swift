import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered study batch.
    final class TieredStudyBatchView {
        var code: String
        var nameText: String
        var acuity: String
        var budget: String
        var updatedAt: String
        var createdAt: String
        var retries: String
        var statusLabel: String

        init(code: String, nameText: String, acuity: String, budget: String, updatedAt: String, createdAt: String, retries: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.acuity = acuity
            self.budget = budget
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toTieredStudyBatchView(_ item: TieredStudyBatch) -> TieredStudyBatchView {
        return TieredStudyBatchView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            acuity: String(item.acuity),
            budget: String(format: "%.2f", item.budget),
            updatedAt: String(item.updatedAt),
            createdAt: String(item.createdAt),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredStudyBatchViews(_ items: [TieredStudyBatch]) -> [TieredStudyBatchView] {
        var views: [TieredStudyBatchView] = []
        for item in items {
            views.append(toTieredStudyBatchView(item))
        }
        return views
    }

    static func sumTieredStudyBatchView(_ view: TieredStudyBatchView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAcuity) + parsedBudget + Double(parsedUpdatedAt)
    }
}
