import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient care protocol claim.
    final class LenientCareProtocolClaimView {
        var code: String
        var labelText: String
        var quantity: String
        var durationMinutes: String
        var graceDays: String
        var statusLabel: String

        init(code: String, labelText: String, quantity: String, durationMinutes: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCareProtocolClaimView(_ item: LenientCareProtocolClaim) -> LenientCareProtocolClaimView {
        return LenientCareProtocolClaimView(
            code: item.code,
            labelText: item.label,
            quantity: String(item.quantity),
            durationMinutes: String(item.durationMinutes),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCareProtocolClaimViews(_ items: [LenientCareProtocolClaim]) -> [LenientCareProtocolClaimView] {
        var views: [LenientCareProtocolClaimView] = []
        for item in items {
            views.append(toLenientCareProtocolClaimView(item))
        }
        return views
    }

    static func sumLenientCareProtocolClaimView(_ view: LenientCareProtocolClaimView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedQuantity) + Double(parsedDurationMinutes) + Double(parsedGraceDays)
    }
}
