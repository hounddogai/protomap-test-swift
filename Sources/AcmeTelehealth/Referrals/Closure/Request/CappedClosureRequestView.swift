import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped closure request.
    final class CappedClosureRequestView {
        var codeText: String
        var title: String
        var contactEmail: String
        var currencyText: String
        var rate: String
        var specialty: String
        var copay: String
        var statusLabel: String

        init(codeText: String, title: String, contactEmail: String, currencyText: String, rate: String, specialty: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.contactEmail = contactEmail
            self.currencyText = currencyText
            self.rate = rate
            self.specialty = specialty
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toCappedClosureRequestView(_ item: CappedClosureRequest) -> CappedClosureRequestView {
        return CappedClosureRequestView(
            codeText: item.code,
            title: item.title,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            currencyText: item.currency,
            rate: String(format: "%.2f", item.rate),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedClosureRequestViews(_ items: [CappedClosureRequest]) -> [CappedClosureRequestView] {
        var views: [CappedClosureRequestView] = []
        for item in items {
            views.append(toCappedClosureRequestView(item))
        }
        return views
    }

    static func sumCappedClosureRequestView(_ view: CappedClosureRequestView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedRate + parsedCopay
    }
}
