import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol review.
    final class CareProtocolReviewView {
        var code: String
        var labelText: String
        var graceDays: String
        var visibleText: String
        var phone: String
        var payer: String
        var statusLabel: String

        init(code: String, labelText: String, graceDays: String, visibleText: String, phone: String, payer: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.graceDays = graceDays
            self.visibleText = visibleText
            self.phone = phone
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolReviewView(_ item: CareProtocolReview) -> CareProtocolReviewView {
        return CareProtocolReviewView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            graceDays: String(item.graceDays),
            visibleText: "\(item.visible)",
            phone: Kit.Text.truncate(item.phone, limit: 120),
            payer: Kit.Text.truncate(item.payer, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolReviewViews(_ items: [CareProtocolReview]) -> [CareProtocolReviewView] {
        var views: [CareProtocolReviewView] = []
        for item in items {
            views.append(toCareProtocolReviewView(item))
        }
        return views
    }

    static func sumCareProtocolReviewView(_ view: CareProtocolReviewView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
