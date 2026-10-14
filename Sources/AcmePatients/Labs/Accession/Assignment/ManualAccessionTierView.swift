import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a manual accession tier.
    final class ManualAccessionTierView {
        var code: String
        var label: String
        var reviewer: String
        var procedureCode: String
        var batchSizeText: String
        var windowDaysText: String
        var regionText: String
        var unitText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, reviewer: String, procedureCode: String, batchSizeText: String, windowDaysText: String, regionText: String, unitText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.batchSizeText = batchSizeText
            self.windowDaysText = windowDaysText
            self.regionText = regionText
            self.unitText = unitText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toManualAccessionTierView(_ item: ManualAccessionTier) -> ManualAccessionTierView {
        return ManualAccessionTierView(
            code: item.code,
            label: item.label,
            reviewer: item.reviewer,
            procedureCode: item.procedureCode,
            batchSizeText: String(item.batchSize),
            windowDaysText: String(item.windowDays),
            regionText: item.region,
            unitText: item.unit,
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualAccessionTierViews(_ items: [ManualAccessionTier]) -> [ManualAccessionTierView] {
        var views: [ManualAccessionTierView] = []
        for item in items {
            views.append(toManualAccessionTierView(item))
        }
        return views
    }

    static func sumManualAccessionTierView(_ view: ManualAccessionTierView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedWindowDays) + Double(parsedUpdatedAt)
    }
}
