import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a strict authorization digest.
    final class StrictAuthorizationDigestView {
        var code: String
        var name: String
        var limitText: String
        var priority: String
        var dosageMgText: String
        var minimum: String
        var phone: String
        var patientRef: String
        var localeText: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, limitText: String, priority: String, dosageMgText: String, minimum: String, phone: String, patientRef: String, localeText: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limitText = limitText
            self.priority = priority
            self.dosageMgText = dosageMgText
            self.minimum = minimum
            self.phone = phone
            self.patientRef = patientRef
            self.localeText = localeText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAuthorizationDigestView(_ item: StrictAuthorizationDigest) -> StrictAuthorizationDigestView {
        return StrictAuthorizationDigestView(
            code: item.code,
            name: item.name,
            limitText: String(item.limit),
            priority: String(item.priority),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            minimum: String(format: "%.2f", item.minimum),
            phone: item.phone,
            patientRef: item.patientRef,
            localeText: item.locale,
            ward: Kit.Text.truncate(item.ward, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAuthorizationDigestViews(_ items: [StrictAuthorizationDigest]) -> [StrictAuthorizationDigestView] {
        var views: [StrictAuthorizationDigestView] = []
        for item in items {
            views.append(toStrictAuthorizationDigestView(item))
        }
        return views
    }

    static func sumStrictAuthorizationDigestView(_ view: StrictAuthorizationDigestView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedLimit) + Double(parsedPriority) + parsedDosageMg
    }
}
