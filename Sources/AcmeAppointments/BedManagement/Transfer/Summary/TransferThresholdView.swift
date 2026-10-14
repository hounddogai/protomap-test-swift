import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer threshold.
    final class TransferThresholdView {
        var codeText: String
        var name: String
        var allergyText: String
        var title: String
        var priority: String
        var payer: String
        var limit: String
        var statusLabel: String

        init(codeText: String, name: String, allergyText: String, title: String, priority: String, payer: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.allergyText = allergyText
            self.title = title
            self.priority = priority
            self.payer = payer
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toTransferThresholdView(_ item: TransferThreshold) -> TransferThresholdView {
        return TransferThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            title: item.title,
            priority: String(item.priority),
            payer: Kit.Text.truncate(item.payer, limit: 120),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferThresholdViews(_ items: [TransferThreshold]) -> [TransferThresholdView] {
        var views: [TransferThresholdView] = []
        for item in items {
            views.append(toTransferThresholdView(item))
        }
        return views
    }

    static func sumTransferThresholdView(_ view: TransferThresholdView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedPriority) + Double(parsedLimit)
    }
}
