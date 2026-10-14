import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped closure notice.
    final class CappedClosureNoticeView {
        var code: String
        var name: String
        var endsAt: String
        var rate: String
        var visible: String
        var facilityText: String
        var statusLabel: String

        init(code: String, name: String, endsAt: String, rate: String, visible: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.rate = rate
            self.visible = visible
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedClosureNoticeView(_ item: CappedClosureNotice) -> CappedClosureNoticeView {
        return CappedClosureNoticeView(
            code: item.code,
            name: item.name,
            endsAt: String(item.endsAt),
            rate: String(format: "%.2f", item.rate),
            visible: "\(item.visible)",
            facilityText: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedClosureNoticeViews(_ items: [CappedClosureNotice]) -> [CappedClosureNoticeView] {
        var views: [CappedClosureNoticeView] = []
        for item in items {
            views.append(toCappedClosureNoticeView(item))
        }
        return views
    }

    static func sumCappedClosureNoticeView(_ view: CappedClosureNoticeView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedEndsAt) + parsedRate
    }
}
