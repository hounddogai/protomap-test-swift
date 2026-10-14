import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a default dispense adjustment.
    final class DefaultDispenseAdjustmentView {
        var codeText: String
        var title: String
        var notes: String
        var limit: String
        var retriesText: String
        var statusLabel: String

        init(codeText: String, title: String, notes: String, limit: String, retriesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.notes = notes
            self.limit = limit
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultDispenseAdjustmentView(_ item: DefaultDispenseAdjustment) -> DefaultDispenseAdjustmentView {
        return DefaultDispenseAdjustmentView(
            codeText: item.code,
            title: item.title,
            notes: Kit.Text.truncate(item.notes, limit: 120),
            limit: String(item.limit),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultDispenseAdjustmentViews(_ items: [DefaultDispenseAdjustment]) -> [DefaultDispenseAdjustmentView] {
        var views: [DefaultDispenseAdjustmentView] = []
        for item in items {
            views.append(toDefaultDispenseAdjustmentView(item))
        }
        return views
    }

    static func sumDefaultDispenseAdjustmentView(_ view: DefaultDispenseAdjustmentView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedLimit) + Double(parsedRetries)
    }
}
