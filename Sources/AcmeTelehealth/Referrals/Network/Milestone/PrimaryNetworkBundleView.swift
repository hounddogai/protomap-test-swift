import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary network bundle.
    final class PrimaryNetworkBundleView {
        var code: String
        var nameText: String
        var margin: String
        var floorValueText: String
        var country: String
        var limit: String
        var bed: String
        var statusLabel: String

        init(code: String, nameText: String, margin: String, floorValueText: String, country: String, limit: String, bed: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.margin = margin
            self.floorValueText = floorValueText
            self.country = country
            self.limit = limit
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryNetworkBundleView(_ item: PrimaryNetworkBundle) -> PrimaryNetworkBundleView {
        return PrimaryNetworkBundleView(
            code: item.code,
            nameText: item.name,
            margin: String(format: "%.2f", item.margin),
            floorValueText: String(format: "%.2f", item.floorValue),
            country: item.country,
            limit: String(item.limit),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryNetworkBundleViews(_ items: [PrimaryNetworkBundle]) -> [PrimaryNetworkBundleView] {
        var views: [PrimaryNetworkBundleView] = []
        for item in items {
            views.append(toPrimaryNetworkBundleView(item))
        }
        return views
    }

    static func sumPrimaryNetworkBundleView(_ view: PrimaryNetworkBundleView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMargin + parsedFloorValue + Double(parsedLimit)
    }
}
