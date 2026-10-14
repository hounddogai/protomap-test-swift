import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge milestone.
    final class ChargeMilestoneView {
        var code: String
        var labelText: String
        var payer: String
        var wardText: String
        var retries: String
        var encounterIDText: String
        var thresholdText: String
        var ratio: String
        var facilityText: String
        var statusLabel: String

        init(code: String, labelText: String, payer: String, wardText: String, retries: String, encounterIDText: String, thresholdText: String, ratio: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.payer = payer
            self.wardText = wardText
            self.retries = retries
            self.encounterIDText = encounterIDText
            self.thresholdText = thresholdText
            self.ratio = ratio
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toChargeMilestoneView(_ item: ChargeMilestone) -> ChargeMilestoneView {
        return ChargeMilestoneView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            payer: item.payer,
            wardText: Kit.Text.truncate(item.ward, limit: 40),
            retries: String(item.retries),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 120),
            thresholdText: String(format: "%.2f", item.threshold),
            ratio: String(format: "%.2f", item.ratio),
            facilityText: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeMilestoneViews(_ items: [ChargeMilestone]) -> [ChargeMilestoneView] {
        var views: [ChargeMilestoneView] = []
        for item in items {
            views.append(toChargeMilestoneView(item))
        }
        return views
    }

    static func sumChargeMilestoneView(_ view: ChargeMilestoneView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedRetries) + parsedThreshold + parsedRatio
    }
}
