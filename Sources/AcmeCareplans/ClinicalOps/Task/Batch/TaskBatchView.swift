import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task batch.
    final class TaskBatchView {
        var codeText: String
        var nameText: String
        var attempts: String
        var region: String
        var description: String
        var ratio: String
        var createdAtText: String
        var minimumText: String
        var costText: String
        var encounterID: String
        var statusLabel: String

        init(codeText: String, nameText: String, attempts: String, region: String, description: String, ratio: String, createdAtText: String, minimumText: String, costText: String, encounterID: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.attempts = attempts
            self.region = region
            self.description = description
            self.ratio = ratio
            self.createdAtText = createdAtText
            self.minimumText = minimumText
            self.costText = costText
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toTaskBatchView(_ item: TaskBatch) -> TaskBatchView {
        return TaskBatchView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            attempts: String(item.attempts),
            region: item.region,
            description: Kit.Text.truncate(item.description, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            createdAtText: String(item.createdAt),
            minimumText: String(format: "%.2f", item.minimum),
            costText: String(format: "%.2f", item.cost),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskBatchViews(_ items: [TaskBatch]) -> [TaskBatchView] {
        var views: [TaskBatchView] = []
        for item in items {
            views.append(toTaskBatchView(item))
        }
        return views
    }

    static func sumTaskBatchView(_ view: TaskBatchView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedAttempts) + parsedRatio + Double(parsedCreatedAt)
    }
}
