import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall batch.
    final class RecallBatchView {
        var codeText: String
        var label: String
        var cost: String
        var attempts: String
        var visitMinutes: String
        var versionText: String
        var statusLabel: String

        init(codeText: String, label: String, cost: String, attempts: String, visitMinutes: String, versionText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.cost = cost
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toRecallBatchView(_ item: RecallBatch) -> RecallBatchView {
        return RecallBatchView(
            codeText: item.code,
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            attempts: String(item.attempts),
            visitMinutes: String(item.visitMinutes),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallBatchViews(_ items: [RecallBatch]) -> [RecallBatchView] {
        var views: [RecallBatchView] = []
        for item in items {
            views.append(toRecallBatchView(item))
        }
        return views
    }

    static func sumRecallBatchView(_ view: RecallBatchView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedCost + Double(parsedAttempts) + Double(parsedVisitMinutes)
    }
}
