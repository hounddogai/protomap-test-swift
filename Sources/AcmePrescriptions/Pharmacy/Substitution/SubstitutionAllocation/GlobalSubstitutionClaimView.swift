import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global substitution claim.
    final class GlobalSubstitutionClaimView {
        var code: String
        var title: String
        var source: String
        var channel: String
        var segment: String
        var quantity: String
        var maximum: String
        var amountText: String
        var unit: String
        var statusLabel: String

        init(code: String, title: String, source: String, channel: String, segment: String, quantity: String, maximum: String, amountText: String, unit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.source = source
            self.channel = channel
            self.segment = segment
            self.quantity = quantity
            self.maximum = maximum
            self.amountText = amountText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSubstitutionClaimView(_ item: GlobalSubstitutionClaim) -> GlobalSubstitutionClaimView {
        return GlobalSubstitutionClaimView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            source: Kit.Text.truncate(item.source, limit: 80),
            channel: item.channel,
            segment: Kit.Text.truncate(item.segment, limit: 80),
            quantity: String(item.quantity),
            maximum: String(format: "%.2f", item.maximum),
            amountText: String(format: "%.2f", item.amount),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSubstitutionClaimViews(_ items: [GlobalSubstitutionClaim]) -> [GlobalSubstitutionClaimView] {
        var views: [GlobalSubstitutionClaimView] = []
        for item in items {
            views.append(toGlobalSubstitutionClaimView(item))
        }
        return views
    }

    static func sumGlobalSubstitutionClaimView(_ view: GlobalSubstitutionClaimView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedQuantity) + parsedMaximum + parsedAmount
    }
}
