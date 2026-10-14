import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional alert notice.
    final class RegionalAlertNoticeView {
        var code: String
        var label: String
        var summary: String
        var sequenceText: String
        var locale: String
        var rate: String
        var payerText: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, label: String, summary: String, sequenceText: String, locale: String, rate: String, payerText: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summary = summary
            self.sequenceText = sequenceText
            self.locale = locale
            self.rate = rate
            self.payerText = payerText
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAlertNoticeView(_ item: RegionalAlertNotice) -> RegionalAlertNoticeView {
        return RegionalAlertNoticeView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            summary: item.summary,
            sequenceText: String(item.sequence),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            rate: String(format: "%.2f", item.rate),
            payerText: Kit.Text.truncate(item.payer, limit: 64),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAlertNoticeViews(_ items: [RegionalAlertNotice]) -> [RegionalAlertNoticeView] {
        var views: [RegionalAlertNoticeView] = []
        for item in items {
            views.append(toRegionalAlertNoticeView(item))
        }
        return views
    }

    static func sumRegionalAlertNoticeView(_ view: RegionalAlertNoticeView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedSequence) + parsedRate
    }
}
