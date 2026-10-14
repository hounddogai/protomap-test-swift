import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default task batch.
    final class DefaultTaskBatchView {
        var code: String
        var titleText: String
        var ownerIDText: String
        var currency: String
        var weightText: String
        var facility: String
        var category: String
        var channel: String
        var graceDays: String
        var statusLabel: String

        init(code: String, titleText: String, ownerIDText: String, currency: String, weightText: String, facility: String, category: String, channel: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ownerIDText = ownerIDText
            self.currency = currency
            self.weightText = weightText
            self.facility = facility
            self.category = category
            self.channel = channel
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultTaskBatchView(_ item: DefaultTaskBatch) -> DefaultTaskBatchView {
        return DefaultTaskBatchView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 80),
            currency: item.currency,
            weightText: String(format: "%.2f", item.weight),
            facility: Kit.Text.truncate(item.facility, limit: 40),
            category: item.category,
            channel: item.channel,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultTaskBatchViews(_ items: [DefaultTaskBatch]) -> [DefaultTaskBatchView] {
        var views: [DefaultTaskBatchView] = []
        for item in items {
            views.append(toDefaultTaskBatchView(item))
        }
        return views
    }

    static func sumDefaultTaskBatchView(_ view: DefaultTaskBatchView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedWeight + Double(parsedGraceDays)
    }
}
