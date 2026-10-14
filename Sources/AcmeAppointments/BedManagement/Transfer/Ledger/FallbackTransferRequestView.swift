import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback transfer request.
    final class FallbackTransferRequestView {
        var code: String
        var titleText: String
        var discount: String
        var visitMinutes: String
        var endsAtText: String
        var statusLabel: String

        init(code: String, titleText: String, discount: String, visitMinutes: String, endsAtText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.discount = discount
            self.visitMinutes = visitMinutes
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackTransferRequestView(_ item: FallbackTransferRequest) -> FallbackTransferRequestView {
        return FallbackTransferRequestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            discount: String(format: "%.2f", item.discount),
            visitMinutes: String(item.visitMinutes),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackTransferRequestViews(_ items: [FallbackTransferRequest]) -> [FallbackTransferRequestView] {
        var views: [FallbackTransferRequestView] = []
        for item in items {
            views.append(toFallbackTransferRequestView(item))
        }
        return views
    }

    static func sumFallbackTransferRequestView(_ view: FallbackTransferRequestView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedDiscount + Double(parsedVisitMinutes) + Double(parsedEndsAt)
    }
}
