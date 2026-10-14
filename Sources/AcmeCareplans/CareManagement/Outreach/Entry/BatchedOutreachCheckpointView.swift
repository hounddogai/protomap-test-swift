import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched outreach checkpoint.
    final class BatchedOutreachCheckpointView {
        var code: String
        var name: String
        var attempts: String
        var rate: String
        var maximumText: String
        var sequence: String
        var wardText: String
        var visible: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, name: String, attempts: String, rate: String, maximumText: String, sequence: String, wardText: String, visible: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.rate = rate
            self.maximumText = maximumText
            self.sequence = sequence
            self.wardText = wardText
            self.visible = visible
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedOutreachCheckpointView(_ item: BatchedOutreachCheckpoint) -> BatchedOutreachCheckpointView {
        return BatchedOutreachCheckpointView(
            code: item.code,
            name: item.name,
            attempts: String(item.attempts),
            rate: String(format: "%.2f", item.rate),
            maximumText: String(format: "%.2f", item.maximum),
            sequence: String(item.sequence),
            wardText: item.ward,
            visible: "\(item.visible)",
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedOutreachCheckpointViews(_ items: [BatchedOutreachCheckpoint]) -> [BatchedOutreachCheckpointView] {
        var views: [BatchedOutreachCheckpointView] = []
        for item in items {
            views.append(toBatchedOutreachCheckpointView(item))
        }
        return views
    }

    static func sumBatchedOutreachCheckpointView(_ view: BatchedOutreachCheckpointView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedAttempts) + parsedRate + parsedMaximum
    }
}
