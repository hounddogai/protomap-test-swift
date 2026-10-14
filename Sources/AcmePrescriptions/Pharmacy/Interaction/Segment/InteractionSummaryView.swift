import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction summary.
    final class InteractionSummaryView {
        var codeText: String
        var title: String
        var windowDays: String
        var maximumText: String
        var weight: String
        var revision: String
        var graceDays: String
        var rateText: String
        var checksum: String
        var copay: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, title: String, windowDays: String, maximumText: String, weight: String, revision: String, graceDays: String, rateText: String, checksum: String, copay: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.windowDays = windowDays
            self.maximumText = maximumText
            self.weight = weight
            self.revision = revision
            self.graceDays = graceDays
            self.rateText = rateText
            self.checksum = checksum
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionSummaryView(_ item: InteractionSummary) -> InteractionSummaryView {
        return InteractionSummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            windowDays: String(item.windowDays),
            maximumText: String(format: "%.2f", item.maximum),
            weight: String(format: "%.2f", item.weight),
            revision: String(item.revision),
            graceDays: String(item.graceDays),
            rateText: String(format: "%.2f", item.rate),
            checksum: item.checksum,
            copay: String(format: "%.2f", item.copay),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionSummaryViews(_ items: [InteractionSummary]) -> [InteractionSummaryView] {
        var views: [InteractionSummaryView] = []
        for item in items {
            views.append(toInteractionSummaryView(item))
        }
        return views
    }

    static func sumInteractionSummaryView(_ view: InteractionSummaryView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedWindowDays) + parsedMaximum + parsedWeight
    }
}
