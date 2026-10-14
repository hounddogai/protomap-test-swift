import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary worklist notice.
    final class PrimaryWorklistNoticeView {
        var code: String
        var labelText: String
        var retriesText: String
        var rate: String
        var timezoneText: String
        var maximum: String
        var refills: String
        var payer: String
        var contactEmailText: String
        var diagnosisCode: String
        var phone: String
        var statusLabel: String

        init(code: String, labelText: String, retriesText: String, rate: String, timezoneText: String, maximum: String, refills: String, payer: String, contactEmailText: String, diagnosisCode: String, phone: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.retriesText = retriesText
            self.rate = rate
            self.timezoneText = timezoneText
            self.maximum = maximum
            self.refills = refills
            self.payer = payer
            self.contactEmailText = contactEmailText
            self.diagnosisCode = diagnosisCode
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryWorklistNoticeView(_ item: PrimaryWorklistNotice) -> PrimaryWorklistNoticeView {
        return PrimaryWorklistNoticeView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            retriesText: String(item.retries),
            rate: String(format: "%.2f", item.rate),
            timezoneText: item.timezone,
            maximum: String(format: "%.2f", item.maximum),
            refills: String(item.refills),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            contactEmailText: item.contactEmail,
            diagnosisCode: item.diagnosisCode,
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryWorklistNoticeViews(_ items: [PrimaryWorklistNotice]) -> [PrimaryWorklistNoticeView] {
        var views: [PrimaryWorklistNoticeView] = []
        for item in items {
            views.append(toPrimaryWorklistNoticeView(item))
        }
        return views
    }

    static func sumPrimaryWorklistNoticeView(_ view: PrimaryWorklistNoticeView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedRetries) + parsedRate + parsedMaximum
    }
}
