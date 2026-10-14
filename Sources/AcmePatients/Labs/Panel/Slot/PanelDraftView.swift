import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel draft.
    final class PanelDraftView {
        var codeText: String
        var title: String
        var amount: String
        var retries: String
        var batchSize: String
        var active: String
        var statusLabel: String

        init(codeText: String, title: String, amount: String, retries: String, batchSize: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.amount = amount
            self.retries = retries
            self.batchSize = batchSize
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toPanelDraftView(_ item: PanelDraft) -> PanelDraftView {
        return PanelDraftView(
            codeText: item.code,
            title: item.title,
            amount: String(format: "%.2f", item.amount),
            retries: String(item.retries),
            batchSize: String(item.batchSize),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelDraftViews(_ items: [PanelDraft]) -> [PanelDraftView] {
        var views: [PanelDraftView] = []
        for item in items {
            views.append(toPanelDraftView(item))
        }
        return views
    }

    static func sumPanelDraftView(_ view: PanelDraftView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedAmount + Double(parsedRetries) + Double(parsedBatchSize)
    }
}
