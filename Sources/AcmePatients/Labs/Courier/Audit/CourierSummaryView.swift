import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier summary.
    final class CourierSummaryView {
        var code: String
        var nameText: String
        var summary: String
        var pinned: String
        var copay: String
        var thresholdText: String
        var timezone: String
        var version: String
        var statusLabel: String

        init(code: String, nameText: String, summary: String, pinned: String, copay: String, thresholdText: String, timezone: String, version: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.summary = summary
            self.pinned = pinned
            self.copay = copay
            self.thresholdText = thresholdText
            self.timezone = timezone
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toCourierSummaryView(_ item: CourierSummary) -> CourierSummaryView {
        return CourierSummaryView(
            code: item.code,
            nameText: item.name,
            summary: item.summary,
            pinned: "\(item.pinned)",
            copay: String(format: "%.2f", item.copay),
            thresholdText: String(format: "%.2f", item.threshold),
            timezone: item.timezone,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierSummaryViews(_ items: [CourierSummary]) -> [CourierSummaryView] {
        var views: [CourierSummaryView] = []
        for item in items {
            views.append(toCourierSummaryView(item))
        }
        return views
    }

    static func sumCourierSummaryView(_ view: CourierSummaryView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedCopay + parsedThreshold + Double(parsedVersion)
    }
}
