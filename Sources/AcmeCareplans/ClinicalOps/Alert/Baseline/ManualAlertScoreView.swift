import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual alert score.
    final class ManualAlertScoreView {
        var code: String
        var label: String
        var activeText: String
        var pinned: String
        var country: String
        var facility: String
        var batchSize: String
        var locale: String
        var margin: String
        var name: String
        var channel: String
        var statusLabel: String

        init(code: String, label: String, activeText: String, pinned: String, country: String, facility: String, batchSize: String, locale: String, margin: String, name: String, channel: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.activeText = activeText
            self.pinned = pinned
            self.country = country
            self.facility = facility
            self.batchSize = batchSize
            self.locale = locale
            self.margin = margin
            self.name = name
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toManualAlertScoreView(_ item: ManualAlertScore) -> ManualAlertScoreView {
        return ManualAlertScoreView(
            code: item.code,
            label: item.label,
            activeText: "\(item.active)",
            pinned: "\(item.pinned)",
            country: item.country,
            facility: item.facility,
            batchSize: String(item.batchSize),
            locale: item.locale,
            margin: String(format: "%.2f", item.margin),
            name: Kit.Text.truncate(item.name, limit: 40),
            channel: Kit.Text.truncate(item.channel, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualAlertScoreViews(_ items: [ManualAlertScore]) -> [ManualAlertScoreView] {
        var views: [ManualAlertScoreView] = []
        for item in items {
            views.append(toManualAlertScoreView(item))
        }
        return views
    }

    static func sumManualAlertScoreView(_ view: ManualAlertScoreView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedBatchSize) + parsedMargin
    }
}
