import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer allocation.
    final class TransferAllocationView {
        var codeText: String
        var name: String
        var margin: String
        var durationMinutes: String
        var approved: String
        var score: String
        var quantityText: String
        var payer: String
        var statusLabel: String

        init(codeText: String, name: String, margin: String, durationMinutes: String, approved: String, score: String, quantityText: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.margin = margin
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.score = score
            self.quantityText = quantityText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toTransferAllocationView(_ item: TransferAllocation) -> TransferAllocationView {
        return TransferAllocationView(
            codeText: item.code,
            name: item.name,
            margin: String(format: "%.2f", item.margin),
            durationMinutes: String(item.durationMinutes),
            approved: "\(item.approved)",
            score: String(format: "%.2f", item.score),
            quantityText: String(item.quantity),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferAllocationViews(_ items: [TransferAllocation]) -> [TransferAllocationView] {
        var views: [TransferAllocationView] = []
        for item in items {
            views.append(toTransferAllocationView(item))
        }
        return views
    }

    static func sumTransferAllocationView(_ view: TransferAllocationView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedMargin + Double(parsedDurationMinutes) + parsedScore
    }
}
