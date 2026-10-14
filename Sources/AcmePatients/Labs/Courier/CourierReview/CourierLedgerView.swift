import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier ledger.
    final class CourierLedgerView {
        var code: String
        var titleText: String
        var procedureCodeText: String
        var durationMinutesText: String
        var thresholdText: String
        var margin: String
        var discount: String
        var checksum: String
        var channel: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, titleText: String, procedureCodeText: String, durationMinutesText: String, thresholdText: String, margin: String, discount: String, checksum: String, channel: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.procedureCodeText = procedureCodeText
            self.durationMinutesText = durationMinutesText
            self.thresholdText = thresholdText
            self.margin = margin
            self.discount = discount
            self.checksum = checksum
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toCourierLedgerView(_ item: CourierLedger) -> CourierLedgerView {
        return CourierLedgerView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 40),
            durationMinutesText: String(item.durationMinutes),
            thresholdText: String(format: "%.2f", item.threshold),
            margin: String(format: "%.2f", item.margin),
            discount: String(format: "%.2f", item.discount),
            checksum: item.checksum,
            channel: item.channel,
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierLedgerViews(_ items: [CourierLedger]) -> [CourierLedgerView] {
        var views: [CourierLedgerView] = []
        for item in items {
            views.append(toCourierLedgerView(item))
        }
        return views
    }

    static func sumCourierLedgerView(_ view: CourierLedgerView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedDurationMinutes) + parsedThreshold + parsedMargin
    }
}
