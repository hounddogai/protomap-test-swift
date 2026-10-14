import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment notice.
    final class AssessmentNoticeView {
        var code: String
        var name: String
        var copay: String
        var marginText: String
        var amountText: String
        var score: String
        var thresholdText: String
        var encounterIDText: String
        var endsAtText: String
        var statusLabel: String

        init(code: String, name: String, copay: String, marginText: String, amountText: String, score: String, thresholdText: String, encounterIDText: String, endsAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.copay = copay
            self.marginText = marginText
            self.amountText = amountText
            self.score = score
            self.thresholdText = thresholdText
            self.encounterIDText = encounterIDText
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentNoticeView(_ item: AssessmentNotice) -> AssessmentNoticeView {
        return AssessmentNoticeView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            copay: String(format: "%.2f", item.copay),
            marginText: String(format: "%.2f", item.margin),
            amountText: String(format: "%.2f", item.amount),
            score: String(format: "%.2f", item.score),
            thresholdText: String(format: "%.2f", item.threshold),
            encounterIDText: item.encounterID,
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentNoticeViews(_ items: [AssessmentNotice]) -> [AssessmentNoticeView] {
        var views: [AssessmentNoticeView] = []
        for item in items {
            views.append(toAssessmentNoticeView(item))
        }
        return views
    }

    static func sumAssessmentNoticeView(_ view: AssessmentNoticeView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedCopay + parsedMargin + parsedAmount
    }
}
