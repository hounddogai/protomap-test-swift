import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime summary.
    final class OvertimeSummaryView {
        var code: String
        var title: String
        var ratioText: String
        var pinned: String
        var floorValueText: String
        var ownerID: String
        var approved: String
        var discountText: String
        var statusLabel: String

        init(code: String, title: String, ratioText: String, pinned: String, floorValueText: String, ownerID: String, approved: String, discountText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ratioText = ratioText
            self.pinned = pinned
            self.floorValueText = floorValueText
            self.ownerID = ownerID
            self.approved = approved
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeSummaryView(_ item: OvertimeSummary) -> OvertimeSummaryView {
        return OvertimeSummaryView(
            code: item.code,
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            pinned: "\(item.pinned)",
            floorValueText: String(format: "%.2f", item.floorValue),
            ownerID: item.ownerID,
            approved: "\(item.approved)",
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeSummaryViews(_ items: [OvertimeSummary]) -> [OvertimeSummaryView] {
        var views: [OvertimeSummaryView] = []
        for item in items {
            views.append(toOvertimeSummaryView(item))
        }
        return views
    }

    static func sumOvertimeSummaryView(_ view: OvertimeSummaryView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedRatio + parsedFloorValue + parsedDiscount
    }
}
