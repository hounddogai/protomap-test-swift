import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict float pool manifest.
    final class StrictFloatPoolManifestView {
        var code: String
        var name: String
        var refills: String
        var revision: String
        var updatedAt: String
        var procedureCode: String
        var floorValueText: String
        var expiresAt: String
        var costText: String
        var graceDaysText: String
        var unitText: String
        var statusLabel: String

        init(code: String, name: String, refills: String, revision: String, updatedAt: String, procedureCode: String, floorValueText: String, expiresAt: String, costText: String, graceDaysText: String, unitText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.refills = refills
            self.revision = revision
            self.updatedAt = updatedAt
            self.procedureCode = procedureCode
            self.floorValueText = floorValueText
            self.expiresAt = expiresAt
            self.costText = costText
            self.graceDaysText = graceDaysText
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictFloatPoolManifestView(_ item: StrictFloatPoolManifest) -> StrictFloatPoolManifestView {
        return StrictFloatPoolManifestView(
            code: item.code,
            name: item.name,
            refills: String(item.refills),
            revision: String(item.revision),
            updatedAt: String(item.updatedAt),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            floorValueText: String(format: "%.2f", item.floorValue),
            expiresAt: String(item.expiresAt),
            costText: String(format: "%.2f", item.cost),
            graceDaysText: String(item.graceDays),
            unitText: Kit.Text.truncate(item.unit, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictFloatPoolManifestViews(_ items: [StrictFloatPoolManifest]) -> [StrictFloatPoolManifestView] {
        var views: [StrictFloatPoolManifestView] = []
        for item in items {
            views.append(toStrictFloatPoolManifestView(item))
        }
        return views
    }

    static func sumStrictFloatPoolManifestView(_ view: StrictFloatPoolManifestView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedRefills) + Double(parsedRevision) + Double(parsedUpdatedAt)
    }
}
