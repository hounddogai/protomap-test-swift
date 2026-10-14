import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional panel digest.
    final class RegionalPanelDigestView {
        var code: String
        var title: String
        var clinicianID: String
        var checksum: String
        var refills: String
        var unitText: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, checksum: String, refills: String, unitText: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.refills = refills
            self.unitText = unitText
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalPanelDigestView(_ item: RegionalPanelDigest) -> RegionalPanelDigestView {
        return RegionalPanelDigestView(
            code: item.code,
            title: item.title,
            clinicianID: item.clinicianID,
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            refills: String(item.refills),
            unitText: item.unit,
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalPanelDigestViews(_ items: [RegionalPanelDigest]) -> [RegionalPanelDigestView] {
        var views: [RegionalPanelDigestView] = []
        for item in items {
            views.append(toRegionalPanelDigestView(item))
        }
        return views
    }

    static func sumRegionalPanelDigestView(_ view: RegionalPanelDigestView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedRefills) + parsedFloorValue
    }
}
