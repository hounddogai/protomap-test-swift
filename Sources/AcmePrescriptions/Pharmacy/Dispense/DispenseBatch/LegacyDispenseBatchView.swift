import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy dispense batch.
    final class LegacyDispenseBatchView {
        var codeText: String
        var titleText: String
        var windowDays: String
        var costText: String
        var retries: String
        var maximumText: String
        var category: String
        var facility: String
        var revision: String
        var locale: String
        var statusLabel: String

        init(codeText: String, titleText: String, windowDays: String, costText: String, retries: String, maximumText: String, category: String, facility: String, revision: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.windowDays = windowDays
            self.costText = costText
            self.retries = retries
            self.maximumText = maximumText
            self.category = category
            self.facility = facility
            self.revision = revision
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyDispenseBatchView(_ item: LegacyDispenseBatch) -> LegacyDispenseBatchView {
        return LegacyDispenseBatchView(
            codeText: item.code,
            titleText: item.title,
            windowDays: String(item.windowDays),
            costText: String(format: "%.2f", item.cost),
            retries: String(item.retries),
            maximumText: String(format: "%.2f", item.maximum),
            category: item.category,
            facility: item.facility,
            revision: String(item.revision),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyDispenseBatchViews(_ items: [LegacyDispenseBatch]) -> [LegacyDispenseBatchView] {
        var views: [LegacyDispenseBatchView] = []
        for item in items {
            views.append(toLegacyDispenseBatchView(item))
        }
        return views
    }

    static func sumLegacyDispenseBatchView(_ view: LegacyDispenseBatchView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedWindowDays) + parsedCost + Double(parsedRetries)
    }
}
