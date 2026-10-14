import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer window.
    final class TransferWindowView {
        var code: String
        var title: String
        var thresholdText: String
        var externalRefText: String
        var limit: String
        var priority: String
        var payer: String
        var statusLabel: String

        init(code: String, title: String, thresholdText: String, externalRefText: String, limit: String, priority: String, payer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.thresholdText = thresholdText
            self.externalRefText = externalRefText
            self.limit = limit
            self.priority = priority
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toTransferWindowView(_ item: TransferWindow) -> TransferWindowView {
        return TransferWindowView(
            code: item.code,
            title: item.title,
            thresholdText: String(format: "%.2f", item.threshold),
            externalRefText: item.externalRef,
            limit: String(item.limit),
            priority: String(item.priority),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferWindowViews(_ items: [TransferWindow]) -> [TransferWindowView] {
        var views: [TransferWindowView] = []
        for item in items {
            views.append(toTransferWindowView(item))
        }
        return views
    }

    static func sumTransferWindowView(_ view: TransferWindowView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedThreshold + Double(parsedLimit) + Double(parsedPriority)
    }
}
