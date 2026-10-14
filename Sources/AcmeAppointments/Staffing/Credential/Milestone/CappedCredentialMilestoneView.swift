import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped credential milestone.
    final class CappedCredentialMilestoneView {
        var code: String
        var title: String
        var channel: String
        var retriesText: String
        var visible: String
        var discountText: String
        var payerText: String
        var checksum: String
        var quantityText: String
        var statusLabel: String

        init(code: String, title: String, channel: String, retriesText: String, visible: String, discountText: String, payerText: String, checksum: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.channel = channel
            self.retriesText = retriesText
            self.visible = visible
            self.discountText = discountText
            self.payerText = payerText
            self.checksum = checksum
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCredentialMilestoneView(_ item: CappedCredentialMilestone) -> CappedCredentialMilestoneView {
        return CappedCredentialMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            retriesText: String(item.retries),
            visible: "\(item.visible)",
            discountText: String(format: "%.2f", item.discount),
            payerText: Kit.Text.truncate(item.payer, limit: 64),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCredentialMilestoneViews(_ items: [CappedCredentialMilestone]) -> [CappedCredentialMilestoneView] {
        var views: [CappedCredentialMilestoneView] = []
        for item in items {
            views.append(toCappedCredentialMilestoneView(item))
        }
        return views
    }

    static func sumCappedCredentialMilestoneView(_ view: CappedCredentialMilestoneView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedRetries) + parsedDiscount + Double(parsedQuantity)
    }
}
