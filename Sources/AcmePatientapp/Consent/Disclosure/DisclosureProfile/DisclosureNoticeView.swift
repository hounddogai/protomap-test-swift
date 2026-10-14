import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure notice.
    final class DisclosureNoticeView {
        var code: String
        var title: String
        var payer: String
        var phone: String
        var discount: String
        var clinicianID: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, payer: String, phone: String, discount: String, clinicianID: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payer = payer
            self.phone = phone
            self.discount = discount
            self.clinicianID = clinicianID
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureNoticeView(_ item: DisclosureNotice) -> DisclosureNoticeView {
        return DisclosureNoticeView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            payer: Kit.Text.truncate(item.payer, limit: 120),
            phone: item.phone,
            discount: String(format: "%.2f", item.discount),
            clinicianID: item.clinicianID,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureNoticeViews(_ items: [DisclosureNotice]) -> [DisclosureNoticeView] {
        var views: [DisclosureNoticeView] = []
        for item in items {
            views.append(toDisclosureNoticeView(item))
        }
        return views
    }

    static func sumDisclosureNoticeView(_ view: DisclosureNoticeView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + Double(parsedCreatedAt)
    }
}
