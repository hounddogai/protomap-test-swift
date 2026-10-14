import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global charge mapping.
    final class GlobalChargeMappingView {
        var code: String
        var nameText: String
        var localeText: String
        var facilityText: String
        var patientRef: String
        var attempts: String
        var region: String
        var retries: String
        var statusLabel: String

        init(code: String, nameText: String, localeText: String, facilityText: String, patientRef: String, attempts: String, region: String, retries: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.localeText = localeText
            self.facilityText = facilityText
            self.patientRef = patientRef
            self.attempts = attempts
            self.region = region
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalChargeMappingView(_ item: GlobalChargeMapping) -> GlobalChargeMappingView {
        return GlobalChargeMappingView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            localeText: Kit.Text.truncate(item.locale, limit: 40),
            facilityText: item.facility,
            patientRef: item.patientRef,
            attempts: String(item.attempts),
            region: item.region,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalChargeMappingViews(_ items: [GlobalChargeMapping]) -> [GlobalChargeMappingView] {
        var views: [GlobalChargeMappingView] = []
        for item in items {
            views.append(toGlobalChargeMappingView(item))
        }
        return views
    }

    static func sumGlobalChargeMappingView(_ view: GlobalChargeMappingView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedAttempts) + Double(parsedRetries)
    }
}
