import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer tier.
    final class TransferTierView {
        var code: String
        var label: String
        var score: String
        var startsAt: String
        var expiresAtText: String
        var priorityText: String
        var batchSize: String
        var specialty: String
        var statusLabel: String

        init(code: String, label: String, score: String, startsAt: String, expiresAtText: String, priorityText: String, batchSize: String, specialty: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.score = score
            self.startsAt = startsAt
            self.expiresAtText = expiresAtText
            self.priorityText = priorityText
            self.batchSize = batchSize
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toTransferTierView(_ item: TransferTier) -> TransferTierView {
        return TransferTierView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            score: String(format: "%.2f", item.score),
            startsAt: String(item.startsAt),
            expiresAtText: String(item.expiresAt),
            priorityText: String(item.priority),
            batchSize: String(item.batchSize),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferTierViews(_ items: [TransferTier]) -> [TransferTierView] {
        var views: [TransferTierView] = []
        for item in items {
            views.append(toTransferTierView(item))
        }
        return views
    }

    static func sumTransferTierView(_ view: TransferTierView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedScore + Double(parsedStartsAt) + Double(parsedExpiresAt)
    }
}
