import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network override.
    final class NetworkOverrideView {
        var code: String
        var name: String
        var allergy: String
        var patientRef: String
        var localeText: String
        var refills: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, patientRef: String, localeText: String, refills: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.patientRef = patientRef
            self.localeText = localeText
            self.refills = refills
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkOverrideView(_ item: NetworkOverride) -> NetworkOverrideView {
        return NetworkOverrideView(
            code: item.code,
            name: item.name,
            allergy: item.allergy,
            patientRef: item.patientRef,
            localeText: item.locale,
            refills: String(item.refills),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkOverrideViews(_ items: [NetworkOverride]) -> [NetworkOverrideView] {
        var views: [NetworkOverrideView] = []
        for item in items {
            views.append(toNetworkOverrideView(item))
        }
        return views
    }

    static func sumNetworkOverrideView(_ view: NetworkOverrideView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedRefills) + Double(parsedStartsAt)
    }
}
