import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network bundle.
    final class NetworkBundleView {
        var codeText: String
        var label: String
        var attempts: String
        var acuityText: String
        var region: String
        var segment: String
        var amount: String
        var statusLabel: String

        init(codeText: String, label: String, attempts: String, acuityText: String, region: String, segment: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.attempts = attempts
            self.acuityText = acuityText
            self.region = region
            self.segment = segment
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkBundleView(_ item: NetworkBundle) -> NetworkBundleView {
        return NetworkBundleView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            attempts: String(item.attempts),
            acuityText: String(item.acuity),
            region: item.region,
            segment: item.segment,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkBundleViews(_ items: [NetworkBundle]) -> [NetworkBundleView] {
        var views: [NetworkBundleView] = []
        for item in items {
            views.append(toNetworkBundleView(item))
        }
        return views
    }

    static func sumNetworkBundleView(_ view: NetworkBundleView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedAttempts) + Double(parsedAcuity) + parsedAmount
    }
}
