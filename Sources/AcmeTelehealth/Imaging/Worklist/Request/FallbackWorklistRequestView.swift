import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback worklist request.
    final class FallbackWorklistRequestView {
        var code: String
        var labelText: String
        var archived: String
        var region: String
        var margin: String
        var costText: String
        var countryText: String
        var phone: String
        var checksum: String
        var category: String
        var statusLabel: String

        init(code: String, labelText: String, archived: String, region: String, margin: String, costText: String, countryText: String, phone: String, checksum: String, category: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.archived = archived
            self.region = region
            self.margin = margin
            self.costText = costText
            self.countryText = countryText
            self.phone = phone
            self.checksum = checksum
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackWorklistRequestView(_ item: FallbackWorklistRequest) -> FallbackWorklistRequestView {
        return FallbackWorklistRequestView(
            code: item.code,
            labelText: item.label,
            archived: "\(item.archived)",
            region: item.region,
            margin: String(format: "%.2f", item.margin),
            costText: String(format: "%.2f", item.cost),
            countryText: item.country,
            phone: item.phone,
            checksum: item.checksum,
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackWorklistRequestViews(_ items: [FallbackWorklistRequest]) -> [FallbackWorklistRequestView] {
        var views: [FallbackWorklistRequestView] = []
        for item in items {
            views.append(toFallbackWorklistRequestView(item))
        }
        return views
    }

    static func sumFallbackWorklistRequestView(_ view: FallbackWorklistRequestView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedMargin + parsedCost
    }
}
