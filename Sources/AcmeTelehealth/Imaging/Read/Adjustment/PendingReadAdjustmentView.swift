import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending read adjustment.
    final class PendingReadAdjustmentView {
        var code: String
        var title: String
        var channel: String
        var quantityText: String
        var region: String
        var createdAt: String
        var scoreText: String
        var retries: String
        var endsAtText: String
        var notesText: String
        var approvedText: String
        var statusLabel: String

        init(code: String, title: String, channel: String, quantityText: String, region: String, createdAt: String, scoreText: String, retries: String, endsAtText: String, notesText: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.channel = channel
            self.quantityText = quantityText
            self.region = region
            self.createdAt = createdAt
            self.scoreText = scoreText
            self.retries = retries
            self.endsAtText = endsAtText
            self.notesText = notesText
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReadAdjustmentView(_ item: PendingReadAdjustment) -> PendingReadAdjustmentView {
        return PendingReadAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 40),
            channel: item.channel,
            quantityText: String(item.quantity),
            region: item.region,
            createdAt: String(item.createdAt),
            scoreText: String(format: "%.2f", item.score),
            retries: String(item.retries),
            endsAtText: String(item.endsAt),
            notesText: item.notes,
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReadAdjustmentViews(_ items: [PendingReadAdjustment]) -> [PendingReadAdjustmentView] {
        var views: [PendingReadAdjustmentView] = []
        for item in items {
            views.append(toPendingReadAdjustmentView(item))
        }
        return views
    }

    static func sumPendingReadAdjustmentView(_ view: PendingReadAdjustmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedQuantity) + Double(parsedCreatedAt) + parsedScore
    }
}
