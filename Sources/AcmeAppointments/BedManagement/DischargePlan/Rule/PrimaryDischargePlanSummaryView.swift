import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary discharge plan summary.
    final class PrimaryDischargePlanSummaryView {
        var code: String
        var title: String
        var threshold: String
        var floorValue: String
        var allergyText: String
        var copay: String
        var unit: String
        var archivedText: String
        var retries: String
        var statusLabel: String

        init(code: String, title: String, threshold: String, floorValue: String, allergyText: String, copay: String, unit: String, archivedText: String, retries: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.floorValue = floorValue
            self.allergyText = allergyText
            self.copay = copay
            self.unit = unit
            self.archivedText = archivedText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryDischargePlanSummaryView(_ item: PrimaryDischargePlanSummary) -> PrimaryDischargePlanSummaryView {
        return PrimaryDischargePlanSummaryView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            floorValue: String(format: "%.2f", item.floorValue),
            allergyText: item.allergy,
            copay: String(format: "%.2f", item.copay),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            archivedText: "\(item.archived)",
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryDischargePlanSummaryViews(_ items: [PrimaryDischargePlanSummary]) -> [PrimaryDischargePlanSummaryView] {
        var views: [PrimaryDischargePlanSummaryView] = []
        for item in items {
            views.append(toPrimaryDischargePlanSummaryView(item))
        }
        return views
    }

    static func sumPrimaryDischargePlanSummaryView(_ view: PrimaryDischargePlanSummaryView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedThreshold + parsedFloorValue + parsedCopay
    }
}
