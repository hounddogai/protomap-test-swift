import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending outreach checkpoint.
    final class PendingOutreachCheckpointView {
        var codeText: String
        var labelText: String
        var visitMinutes: String
        var minimum: String
        var createdAt: String
        var category: String
        var source: String
        var statusLabel: String

        init(codeText: String, labelText: String, visitMinutes: String, minimum: String, createdAt: String, category: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.visitMinutes = visitMinutes
            self.minimum = minimum
            self.createdAt = createdAt
            self.category = category
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toPendingOutreachCheckpointView(_ item: PendingOutreachCheckpoint) -> PendingOutreachCheckpointView {
        return PendingOutreachCheckpointView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            visitMinutes: String(item.visitMinutes),
            minimum: String(format: "%.2f", item.minimum),
            createdAt: String(item.createdAt),
            category: Kit.Text.truncate(item.category, limit: 120),
            source: Kit.Text.truncate(item.source, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingOutreachCheckpointViews(_ items: [PendingOutreachCheckpoint]) -> [PendingOutreachCheckpointView] {
        var views: [PendingOutreachCheckpointView] = []
        for item in items {
            views.append(toPendingOutreachCheckpointView(item))
        }
        return views
    }

    static func sumPendingOutreachCheckpointView(_ view: PendingOutreachCheckpointView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedVisitMinutes) + parsedMinimum + Double(parsedCreatedAt)
    }
}
