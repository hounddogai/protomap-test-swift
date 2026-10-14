import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped statement digest.
    final class CappedStatementDigestView {
        var codeText: String
        var label: String
        var summary: String
        var pinnedText: String
        var channel: String
        var amount: String
        var statusLabel: String

        init(codeText: String, label: String, summary: String, pinnedText: String, channel: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.summary = summary
            self.pinnedText = pinnedText
            self.channel = channel
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toCappedStatementDigestView(_ item: CappedStatementDigest) -> CappedStatementDigestView {
        return CappedStatementDigestView(
            codeText: item.code,
            label: item.label,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            pinnedText: "\(item.pinned)",
            channel: Kit.Text.truncate(item.channel, limit: 64),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedStatementDigestViews(_ items: [CappedStatementDigest]) -> [CappedStatementDigestView] {
        var views: [CappedStatementDigestView] = []
        for item in items {
            views.append(toCappedStatementDigestView(item))
        }
        return views
    }

    static func sumCappedStatementDigestView(_ view: CappedStatementDigestView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
