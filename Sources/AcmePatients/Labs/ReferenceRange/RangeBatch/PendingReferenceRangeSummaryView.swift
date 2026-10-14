import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending reference range summary.
    final class PendingReferenceRangeSummaryView {
        var code: String
        var title: String
        var ceiling: String
        var ownerID: String
        var unit: String
        var channelText: String
        var ward: String
        var patientRef: String
        var windowDays: String
        var retriesText: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, ownerID: String, unit: String, channelText: String, ward: String, patientRef: String, windowDays: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.unit = unit
            self.channelText = channelText
            self.ward = ward
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReferenceRangeSummaryView(_ item: PendingReferenceRangeSummary) -> PendingReferenceRangeSummaryView {
        return PendingReferenceRangeSummaryView(
            code: item.code,
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            ownerID: item.ownerID,
            unit: item.unit,
            channelText: item.channel,
            ward: item.ward,
            patientRef: item.patientRef,
            windowDays: String(item.windowDays),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReferenceRangeSummaryViews(_ items: [PendingReferenceRangeSummary]) -> [PendingReferenceRangeSummaryView] {
        var views: [PendingReferenceRangeSummaryView] = []
        for item in items {
            views.append(toPendingReferenceRangeSummaryView(item))
        }
        return views
    }

    static func sumPendingReferenceRangeSummaryView(_ view: PendingReferenceRangeSummaryView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedCeiling + Double(parsedWindowDays) + Double(parsedRetries)
    }
}
