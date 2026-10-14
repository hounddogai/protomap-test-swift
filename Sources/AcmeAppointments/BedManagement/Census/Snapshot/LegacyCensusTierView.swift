import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy census tier.
    final class LegacyCensusTierView {
        var code: String
        var label: String
        var windowDays: String
        var startsAt: String
        var batchSizeText: String
        var threshold: String
        var patientRef: String
        var statusLabel: String

        init(code: String, label: String, windowDays: String, startsAt: String, batchSizeText: String, threshold: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.startsAt = startsAt
            self.batchSizeText = batchSizeText
            self.threshold = threshold
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCensusTierView(_ item: LegacyCensusTier) -> LegacyCensusTierView {
        return LegacyCensusTierView(
            code: item.code,
            label: item.label,
            windowDays: String(item.windowDays),
            startsAt: String(item.startsAt),
            batchSizeText: String(item.batchSize),
            threshold: String(format: "%.2f", item.threshold),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCensusTierViews(_ items: [LegacyCensusTier]) -> [LegacyCensusTierView] {
        var views: [LegacyCensusTierView] = []
        for item in items {
            views.append(toLegacyCensusTierView(item))
        }
        return views
    }

    static func sumLegacyCensusTierView(_ view: LegacyCensusTierView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedStartsAt) + Double(parsedBatchSize)
    }
}
