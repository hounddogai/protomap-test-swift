import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive discharge plan bundle.
    final class AdaptiveDischargePlanBundleView {
        var code: String
        var label: String
        var name: String
        var weight: String
        var versionText: String
        var copay: String
        var encounterID: String
        var contactEmail: String
        var refills: String
        var statusLabel: String

        init(code: String, label: String, name: String, weight: String, versionText: String, copay: String, encounterID: String, contactEmail: String, refills: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.weight = weight
            self.versionText = versionText
            self.copay = copay
            self.encounterID = encounterID
            self.contactEmail = contactEmail
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDischargePlanBundleView(_ item: AdaptiveDischargePlanBundle) -> AdaptiveDischargePlanBundleView {
        return AdaptiveDischargePlanBundleView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            weight: String(format: "%.2f", item.weight),
            versionText: String(item.version),
            copay: String(format: "%.2f", item.copay),
            encounterID: item.encounterID,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDischargePlanBundleViews(_ items: [AdaptiveDischargePlanBundle]) -> [AdaptiveDischargePlanBundleView] {
        var views: [AdaptiveDischargePlanBundleView] = []
        for item in items {
            views.append(toAdaptiveDischargePlanBundleView(item))
        }
        return views
    }

    static func sumAdaptiveDischargePlanBundleView(_ view: AdaptiveDischargePlanBundleView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedWeight + Double(parsedVersion) + parsedCopay
    }
}
