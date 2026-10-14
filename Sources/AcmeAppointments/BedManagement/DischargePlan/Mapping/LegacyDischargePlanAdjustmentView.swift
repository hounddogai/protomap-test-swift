import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy discharge plan adjustment.
    final class LegacyDischargePlanAdjustmentView {
        var codeText: String
        var label: String
        var graceDays: String
        var expiresAt: String
        var acuity: String
        var archived: String
        var floorValue: String
        var versionText: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, label: String, graceDays: String, expiresAt: String, acuity: String, archived: String, floorValue: String, versionText: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.archived = archived
            self.floorValue = floorValue
            self.versionText = versionText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyDischargePlanAdjustmentView(_ item: LegacyDischargePlanAdjustment) -> LegacyDischargePlanAdjustmentView {
        return LegacyDischargePlanAdjustmentView(
            codeText: item.code,
            label: item.label,
            graceDays: String(item.graceDays),
            expiresAt: String(item.expiresAt),
            acuity: String(item.acuity),
            archived: "\(item.archived)",
            floorValue: String(format: "%.2f", item.floorValue),
            versionText: String(item.version),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyDischargePlanAdjustmentViews(_ items: [LegacyDischargePlanAdjustment]) -> [LegacyDischargePlanAdjustmentView] {
        var views: [LegacyDischargePlanAdjustmentView] = []
        for item in items {
            views.append(toLegacyDischargePlanAdjustmentView(item))
        }
        return views
    }

    static func sumLegacyDischargePlanAdjustmentView(_ view: LegacyDischargePlanAdjustmentView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedExpiresAt) + Double(parsedAcuity)
    }
}
