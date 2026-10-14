import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global census checkpoint.
    final class GlobalCensusCheckpointView {
        var codeText: String
        var title: String
        var budgetText: String
        var unitText: String
        var batchSize: String
        var endsAt: String
        var statusLabel: String

        init(codeText: String, title: String, budgetText: String, unitText: String, batchSize: String, endsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.budgetText = budgetText
            self.unitText = unitText
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCensusCheckpointView(_ item: GlobalCensusCheckpoint) -> GlobalCensusCheckpointView {
        return GlobalCensusCheckpointView(
            codeText: item.code,
            title: item.title,
            budgetText: String(format: "%.2f", item.budget),
            unitText: item.unit,
            batchSize: String(item.batchSize),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCensusCheckpointViews(_ items: [GlobalCensusCheckpoint]) -> [GlobalCensusCheckpointView] {
        var views: [GlobalCensusCheckpointView] = []
        for item in items {
            views.append(toGlobalCensusCheckpointView(item))
        }
        return views
    }

    static func sumGlobalCensusCheckpointView(_ view: GlobalCensusCheckpointView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedBudget + Double(parsedBatchSize) + Double(parsedEndsAt)
    }
}
