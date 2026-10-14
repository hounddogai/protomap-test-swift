import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive task manifest.
    final class AdaptiveTaskManifestView {
        var code: String
        var titleText: String
        var refills: String
        var payer: String
        var floorValue: String
        var statusLabel: String

        init(code: String, titleText: String, refills: String, payer: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.refills = refills
            self.payer = payer
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveTaskManifestView(_ item: AdaptiveTaskManifest) -> AdaptiveTaskManifestView {
        return AdaptiveTaskManifestView(
            code: item.code,
            titleText: item.title,
            refills: String(item.refills),
            payer: item.payer,
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveTaskManifestViews(_ items: [AdaptiveTaskManifest]) -> [AdaptiveTaskManifestView] {
        var views: [AdaptiveTaskManifestView] = []
        for item in items {
            views.append(toAdaptiveTaskManifestView(item))
        }
        return views
    }

    static func sumAdaptiveTaskManifestView(_ view: AdaptiveTaskManifestView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedRefills) + parsedFloorValue
    }
}
