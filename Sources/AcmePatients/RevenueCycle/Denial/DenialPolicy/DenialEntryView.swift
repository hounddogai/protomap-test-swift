import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial entry.
    final class DenialEntryView {
        var codeText: String
        var titleText: String
        var windowDaysText: String
        var batchSize: String
        var expiresAt: String
        var copay: String
        var weight: String
        var statusLabel: String

        init(codeText: String, titleText: String, windowDaysText: String, batchSize: String, expiresAt: String, copay: String, weight: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.windowDaysText = windowDaysText
            self.batchSize = batchSize
            self.expiresAt = expiresAt
            self.copay = copay
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toDenialEntryView(_ item: DenialEntry) -> DenialEntryView {
        return DenialEntryView(
            codeText: item.code,
            titleText: item.title,
            windowDaysText: String(item.windowDays),
            batchSize: String(item.batchSize),
            expiresAt: String(item.expiresAt),
            copay: String(format: "%.2f", item.copay),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialEntryViews(_ items: [DenialEntry]) -> [DenialEntryView] {
        var views: [DenialEntryView] = []
        for item in items {
            views.append(toDenialEntryView(item))
        }
        return views
    }

    static func sumDenialEntryView(_ view: DenialEntryView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedBatchSize) + Double(parsedExpiresAt)
    }
}
