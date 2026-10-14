import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default charge mapping.
    final class DefaultChargeMappingView {
        var code: String
        var labelText: String
        var acuity: String
        var maximumText: String
        var ownerID: String
        var ceiling: String
        var clinicianID: String
        var encounterIDText: String
        var version: String
        var endsAt: String
        var statusLabel: String

        init(code: String, labelText: String, acuity: String, maximumText: String, ownerID: String, ceiling: String, clinicianID: String, encounterIDText: String, version: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.acuity = acuity
            self.maximumText = maximumText
            self.ownerID = ownerID
            self.ceiling = ceiling
            self.clinicianID = clinicianID
            self.encounterIDText = encounterIDText
            self.version = version
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultChargeMappingView(_ item: DefaultChargeMapping) -> DefaultChargeMappingView {
        return DefaultChargeMappingView(
            code: item.code,
            labelText: item.label,
            acuity: String(item.acuity),
            maximumText: String(format: "%.2f", item.maximum),
            ownerID: item.ownerID,
            ceiling: String(format: "%.2f", item.ceiling),
            clinicianID: item.clinicianID,
            encounterIDText: item.encounterID,
            version: String(item.version),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultChargeMappingViews(_ items: [DefaultChargeMapping]) -> [DefaultChargeMappingView] {
        var views: [DefaultChargeMappingView] = []
        for item in items {
            views.append(toDefaultChargeMappingView(item))
        }
        return views
    }

    static func sumDefaultChargeMappingView(_ view: DefaultChargeMappingView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedAcuity) + parsedMaximum + parsedCeiling
    }
}
