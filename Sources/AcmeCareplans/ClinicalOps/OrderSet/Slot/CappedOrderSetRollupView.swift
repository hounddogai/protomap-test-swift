import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a capped order set rollup.
    final class CappedOrderSetRollupView {
        var codeText: String
        var label: String
        var facility: String
        var updatedAtText: String
        var timezoneText: String
        var minimumText: String
        var reviewerText: String
        var statusLabel: String

        init(codeText: String, label: String, facility: String, updatedAtText: String, timezoneText: String, minimumText: String, reviewerText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.facility = facility
            self.updatedAtText = updatedAtText
            self.timezoneText = timezoneText
            self.minimumText = minimumText
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedOrderSetRollupView(_ item: CappedOrderSetRollup) -> CappedOrderSetRollupView {
        return CappedOrderSetRollupView(
            codeText: item.code,
            label: item.label,
            facility: item.facility,
            updatedAtText: String(item.updatedAt),
            timezoneText: item.timezone,
            minimumText: String(format: "%.2f", item.minimum),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedOrderSetRollupViews(_ items: [CappedOrderSetRollup]) -> [CappedOrderSetRollupView] {
        var views: [CappedOrderSetRollupView] = []
        for item in items {
            views.append(toCappedOrderSetRollupView(item))
        }
        return views
    }

    static func sumCappedOrderSetRollupView(_ view: CappedOrderSetRollupView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMinimum
    }
}
