import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual revocation segment.
    final class ManualRevocationSegmentView {
        var code: String
        var name: String
        var windowDays: String
        var batchSize: String
        var summary: String
        var activeText: String
        var bedText: String
        var timezoneText: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, name: String, windowDays: String, batchSize: String, summary: String, activeText: String, bedText: String, timezoneText: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.summary = summary
            self.activeText = activeText
            self.bedText = bedText
            self.timezoneText = timezoneText
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toManualRevocationSegmentView(_ item: ManualRevocationSegment) -> ManualRevocationSegmentView {
        return ManualRevocationSegmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            windowDays: String(item.windowDays),
            batchSize: String(item.batchSize),
            summary: item.summary,
            activeText: "\(item.active)",
            bedText: item.bed,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 80),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRevocationSegmentViews(_ items: [ManualRevocationSegment]) -> [ManualRevocationSegmentView] {
        var views: [ManualRevocationSegmentView] = []
        for item in items {
            views.append(toManualRevocationSegmentView(item))
        }
        return views
    }

    static func sumManualRevocationSegmentView(_ view: ManualRevocationSegmentView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedBatchSize)
    }
}
