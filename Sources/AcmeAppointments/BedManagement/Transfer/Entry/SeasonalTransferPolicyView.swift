import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a seasonal transfer policy.
    final class SeasonalTransferPolicyView {
        var code: String
        var name: String
        var unit: String
        var refills: String
        var createdAt: String
        var acuity: String
        var titleText: String
        var thresholdText: String
        var contactEmail: String
        var patientRef: String
        var locale: String
        var statusLabel: String

        init(code: String, name: String, unit: String, refills: String, createdAt: String, acuity: String, titleText: String, thresholdText: String, contactEmail: String, patientRef: String, locale: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unit = unit
            self.refills = refills
            self.createdAt = createdAt
            self.acuity = acuity
            self.titleText = titleText
            self.thresholdText = thresholdText
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalTransferPolicyView(_ item: SeasonalTransferPolicy) -> SeasonalTransferPolicyView {
        return SeasonalTransferPolicyView(
            code: item.code,
            name: item.name,
            unit: Kit.Text.truncate(item.unit, limit: 120),
            refills: String(item.refills),
            createdAt: String(item.createdAt),
            acuity: String(item.acuity),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            thresholdText: String(format: "%.2f", item.threshold),
            contactEmail: item.contactEmail,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalTransferPolicyViews(_ items: [SeasonalTransferPolicy]) -> [SeasonalTransferPolicyView] {
        var views: [SeasonalTransferPolicyView] = []
        for item in items {
            views.append(toSeasonalTransferPolicyView(item))
        }
        return views
    }

    static func sumSeasonalTransferPolicyView(_ view: SeasonalTransferPolicyView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedRefills) + Double(parsedCreatedAt) + Double(parsedAcuity)
    }
}
