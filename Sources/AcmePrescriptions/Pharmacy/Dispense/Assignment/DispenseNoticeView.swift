import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense notice.
    final class DispenseNoticeView {
        var codeText: String
        var title: String
        var rateText: String
        var currency: String
        var acuityText: String
        var statusLabel: String

        init(codeText: String, title: String, rateText: String, currency: String, acuityText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.rateText = rateText
            self.currency = currency
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseNoticeView(_ item: DispenseNotice) -> DispenseNoticeView {
        return DispenseNoticeView(
            codeText: item.code,
            title: item.title,
            rateText: String(format: "%.2f", item.rate),
            currency: item.currency,
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseNoticeViews(_ items: [DispenseNotice]) -> [DispenseNoticeView] {
        var views: [DispenseNoticeView] = []
        for item in items {
            views.append(toDispenseNoticeView(item))
        }
        return views
    }

    static func sumDispenseNoticeView(_ view: DispenseNoticeView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedRate + Double(parsedAcuity)
    }
}
