import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global network record.
    final class GlobalNetworkRecordView {
        var code: String
        var labelText: String
        var source: String
        var maximum: String
        var patientRef: String
        var rateText: String
        var encounterID: String
        var retries: String
        var statusLabel: String

        init(code: String, labelText: String, source: String, maximum: String, patientRef: String, rateText: String, encounterID: String, retries: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.source = source
            self.maximum = maximum
            self.patientRef = patientRef
            self.rateText = rateText
            self.encounterID = encounterID
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalNetworkRecordView(_ item: GlobalNetworkRecord) -> GlobalNetworkRecordView {
        return GlobalNetworkRecordView(
            code: item.code,
            labelText: item.label,
            source: item.source,
            maximum: String(format: "%.2f", item.maximum),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            rateText: String(format: "%.2f", item.rate),
            encounterID: item.encounterID,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalNetworkRecordViews(_ items: [GlobalNetworkRecord]) -> [GlobalNetworkRecordView] {
        var views: [GlobalNetworkRecordView] = []
        for item in items {
            views.append(toGlobalNetworkRecordView(item))
        }
        return views
    }

    static func sumGlobalNetworkRecordView(_ view: GlobalNetworkRecordView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedMaximum + parsedRate + Double(parsedRetries)
    }
}
