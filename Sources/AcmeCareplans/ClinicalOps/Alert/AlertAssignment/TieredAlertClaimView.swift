import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered alert claim.
    final class TieredAlertClaimView {
        var codeText: String
        var title: String
        var limitText: String
        var pinned: String
        var ceiling: String
        var weightText: String
        var bedText: String
        var visible: String
        var retries: String
        var clinicianIDText: String
        var ward: String
        var statusLabel: String

        init(codeText: String, title: String, limitText: String, pinned: String, ceiling: String, weightText: String, bedText: String, visible: String, retries: String, clinicianIDText: String, ward: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.limitText = limitText
            self.pinned = pinned
            self.ceiling = ceiling
            self.weightText = weightText
            self.bedText = bedText
            self.visible = visible
            self.retries = retries
            self.clinicianIDText = clinicianIDText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAlertClaimView(_ item: TieredAlertClaim) -> TieredAlertClaimView {
        return TieredAlertClaimView(
            codeText: item.code,
            title: item.title,
            limitText: String(item.limit),
            pinned: "\(item.pinned)",
            ceiling: String(format: "%.2f", item.ceiling),
            weightText: String(format: "%.2f", item.weight),
            bedText: Kit.Text.truncate(item.bed, limit: 64),
            visible: "\(item.visible)",
            retries: String(item.retries),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 80),
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAlertClaimViews(_ items: [TieredAlertClaim]) -> [TieredAlertClaimView] {
        var views: [TieredAlertClaimView] = []
        for item in items {
            views.append(toTieredAlertClaimView(item))
        }
        return views
    }

    static func sumTieredAlertClaimView(_ view: TieredAlertClaimView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedLimit) + parsedCeiling + parsedWeight
    }
}
