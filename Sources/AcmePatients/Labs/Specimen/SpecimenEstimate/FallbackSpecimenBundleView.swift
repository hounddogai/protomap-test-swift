import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback specimen bundle.
    final class FallbackSpecimenBundleView {
        var code: String
        var label: String
        var revision: String
        var floorValueText: String
        var unitText: String
        var statusLabel: String

        init(code: String, label: String, revision: String, floorValueText: String, unitText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.revision = revision
            self.floorValueText = floorValueText
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackSpecimenBundleView(_ item: FallbackSpecimenBundle) -> FallbackSpecimenBundleView {
        return FallbackSpecimenBundleView(
            code: item.code,
            label: item.label,
            revision: String(item.revision),
            floorValueText: String(format: "%.2f", item.floorValue),
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackSpecimenBundleViews(_ items: [FallbackSpecimenBundle]) -> [FallbackSpecimenBundleView] {
        var views: [FallbackSpecimenBundleView] = []
        for item in items {
            views.append(toFallbackSpecimenBundleView(item))
        }
        return views
    }

    static func sumFallbackSpecimenBundleView(_ view: FallbackSpecimenBundleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedRevision) + parsedFloorValue
    }
}
