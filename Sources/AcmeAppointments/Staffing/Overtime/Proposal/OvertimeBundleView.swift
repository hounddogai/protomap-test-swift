import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime bundle.
    final class OvertimeBundleView {
        var code: String
        var titleText: String
        var graceDays: String
        var approved: String
        var discount: String
        var statusLabel: String

        init(code: String, titleText: String, graceDays: String, approved: String, discount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.graceDays = graceDays
            self.approved = approved
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeBundleView(_ item: OvertimeBundle) -> OvertimeBundleView {
        return OvertimeBundleView(
            code: item.code,
            titleText: item.title,
            graceDays: String(item.graceDays),
            approved: "\(item.approved)",
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeBundleViews(_ items: [OvertimeBundle]) -> [OvertimeBundleView] {
        var views: [OvertimeBundleView] = []
        for item in items {
            views.append(toOvertimeBundleView(item))
        }
        return views
    }

    static func sumOvertimeBundleView(_ view: OvertimeBundleView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedGraceDays) + parsedDiscount
    }
}
