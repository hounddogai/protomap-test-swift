import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled care protocol summary.
    final class ScheduledCareProtocolSummaryView {
        var codeText: String
        var label: String
        var allergy: String
        var facility: String
        var rate: String
        var externalRefText: String
        var statusLabel: String

        init(codeText: String, label: String, allergy: String, facility: String, rate: String, externalRefText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.allergy = allergy
            self.facility = facility
            self.rate = rate
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCareProtocolSummaryView(_ item: ScheduledCareProtocolSummary) -> ScheduledCareProtocolSummaryView {
        return ScheduledCareProtocolSummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            allergy: item.allergy,
            facility: item.facility,
            rate: String(format: "%.2f", item.rate),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCareProtocolSummaryViews(_ items: [ScheduledCareProtocolSummary]) -> [ScheduledCareProtocolSummaryView] {
        var views: [ScheduledCareProtocolSummaryView] = []
        for item in items {
            views.append(toScheduledCareProtocolSummaryView(item))
        }
        return views
    }

    static func sumScheduledCareProtocolSummaryView(_ view: ScheduledCareProtocolSummaryView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRate
    }
}
