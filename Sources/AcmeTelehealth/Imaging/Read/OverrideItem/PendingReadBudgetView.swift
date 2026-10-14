import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending read budget.
    final class PendingReadBudgetView {
        var codeText: String
        var nameText: String
        var channel: String
        var copay: String
        var source: String
        var statusLabel: String

        init(codeText: String, nameText: String, channel: String, copay: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.channel = channel
            self.copay = copay
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReadBudgetView(_ item: PendingReadBudget) -> PendingReadBudgetView {
        return PendingReadBudgetView(
            codeText: item.code,
            nameText: item.name,
            channel: item.channel,
            copay: String(format: "%.2f", item.copay),
            source: Kit.Text.truncate(item.source, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReadBudgetViews(_ items: [PendingReadBudget]) -> [PendingReadBudgetView] {
        var views: [PendingReadBudgetView] = []
        for item in items {
            views.append(toPendingReadBudgetView(item))
        }
        return views
    }

    static func sumPendingReadBudgetView(_ view: PendingReadBudgetView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
