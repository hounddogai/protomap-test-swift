import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered eligibility record.
    final class TieredEligibilityRecordView {
        var code: String
        var title: String
        var reviewer: String
        var windowDaysText: String
        var active: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, title: String, reviewer: String, windowDaysText: String, active: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.windowDaysText = windowDaysText
            self.active = active
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredEligibilityRecordView(_ item: TieredEligibilityRecord) -> TieredEligibilityRecordView {
        return TieredEligibilityRecordView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 40),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            windowDaysText: String(item.windowDays),
            active: "\(item.active)",
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredEligibilityRecordViews(_ items: [TieredEligibilityRecord]) -> [TieredEligibilityRecordView] {
        var views: [TieredEligibilityRecordView] = []
        for item in items {
            views.append(toTieredEligibilityRecordView(item))
        }
        return views
    }

    static func sumTieredEligibilityRecordView(_ view: TieredEligibilityRecordView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedBatchSize)
    }
}
