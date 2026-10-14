import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient discharge plan quota.
    final class LenientDischargePlanQuotaView {
        var codeText: String
        var label: String
        var titleText: String
        var floorValue: String
        var encounterID: String
        var statusLabel: String

        init(codeText: String, label: String, titleText: String, floorValue: String, encounterID: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.titleText = titleText
            self.floorValue = floorValue
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toLenientDischargePlanQuotaView(_ item: LenientDischargePlanQuota) -> LenientDischargePlanQuotaView {
        return LenientDischargePlanQuotaView(
            codeText: item.code,
            label: item.label,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientDischargePlanQuotaViews(_ items: [LenientDischargePlanQuota]) -> [LenientDischargePlanQuotaView] {
        var views: [LenientDischargePlanQuotaView] = []
        for item in items {
            views.append(toLenientDischargePlanQuotaView(item))
        }
        return views
    }

    static func sumLenientDischargePlanQuotaView(_ view: LenientDischargePlanQuotaView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
