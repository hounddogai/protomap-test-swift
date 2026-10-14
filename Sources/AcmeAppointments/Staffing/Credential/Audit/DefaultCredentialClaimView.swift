import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default credential claim.
    final class DefaultCredentialClaimView {
        var code: String
        var title: String
        var amount: String
        var dosageMgText: String
        var minimumText: String
        var channelText: String
        var statusLabel: String

        init(code: String, title: String, amount: String, dosageMgText: String, minimumText: String, channelText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.amount = amount
            self.dosageMgText = dosageMgText
            self.minimumText = minimumText
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCredentialClaimView(_ item: DefaultCredentialClaim) -> DefaultCredentialClaimView {
        return DefaultCredentialClaimView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            amount: String(format: "%.2f", item.amount),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            minimumText: String(format: "%.2f", item.minimum),
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCredentialClaimViews(_ items: [DefaultCredentialClaim]) -> [DefaultCredentialClaimView] {
        var views: [DefaultCredentialClaimView] = []
        for item in items {
            views.append(toDefaultCredentialClaimView(item))
        }
        return views
    }

    static func sumDefaultCredentialClaimView(_ view: DefaultCredentialClaimView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedAmount + parsedDosageMg + parsedMinimum
    }
}
