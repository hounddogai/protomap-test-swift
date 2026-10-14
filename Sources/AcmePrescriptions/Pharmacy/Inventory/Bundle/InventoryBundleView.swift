import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory bundle.
    final class InventoryBundleView {
        var codeText: String
        var title: String
        var maximum: String
        var externalRef: String
        var clinicianID: String
        var payer: String
        var version: String
        var revision: String
        var allergy: String
        var locale: String
        var statusLabel: String

        init(codeText: String, title: String, maximum: String, externalRef: String, clinicianID: String, payer: String, version: String, revision: String, allergy: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.maximum = maximum
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.payer = payer
            self.version = version
            self.revision = revision
            self.allergy = allergy
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryBundleView(_ item: InventoryBundle) -> InventoryBundleView {
        return InventoryBundleView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            externalRef: item.externalRef,
            clinicianID: item.clinicianID,
            payer: item.payer,
            version: String(item.version),
            revision: String(item.revision),
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            locale: Kit.Text.truncate(item.locale, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryBundleViews(_ items: [InventoryBundle]) -> [InventoryBundleView] {
        var views: [InventoryBundleView] = []
        for item in items {
            views.append(toInventoryBundleView(item))
        }
        return views
    }

    static func sumInventoryBundleView(_ view: InventoryBundleView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedMaximum + Double(parsedVersion) + Double(parsedRevision)
    }
}
