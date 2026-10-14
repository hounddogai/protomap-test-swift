import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure bundle.
    final class ClosureBundleView {
        var code: String
        var titleText: String
        var ownerIDText: String
        var allergyText: String
        var visitMinutes: String
        var summaryText: String
        var statusLabel: String

        init(code: String, titleText: String, ownerIDText: String, allergyText: String, visitMinutes: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ownerIDText = ownerIDText
            self.allergyText = allergyText
            self.visitMinutes = visitMinutes
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureBundleView(_ item: ClosureBundle) -> ClosureBundleView {
        return ClosureBundleView(
            code: item.code,
            titleText: item.title,
            ownerIDText: item.ownerID,
            allergyText: item.allergy,
            visitMinutes: String(item.visitMinutes),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureBundleViews(_ items: [ClosureBundle]) -> [ClosureBundleView] {
        var views: [ClosureBundleView] = []
        for item in items {
            views.append(toClosureBundleView(item))
        }
        return views
    }

    static func sumClosureBundleView(_ view: ClosureBundleView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
