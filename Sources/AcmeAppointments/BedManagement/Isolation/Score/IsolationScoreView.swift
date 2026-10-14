import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation score.
    final class IsolationScoreView {
        var code: String
        var titleText: String
        var externalRefText: String
        var country: String
        var endsAt: String
        var refills: String
        var statusLabel: String

        init(code: String, titleText: String, externalRefText: String, country: String, endsAt: String, refills: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.externalRefText = externalRefText
            self.country = country
            self.endsAt = endsAt
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationScoreView(_ item: IsolationScore) -> IsolationScoreView {
        return IsolationScoreView(
            code: item.code,
            titleText: item.title,
            externalRefText: item.externalRef,
            country: item.country,
            endsAt: String(item.endsAt),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationScoreViews(_ items: [IsolationScore]) -> [IsolationScoreView] {
        var views: [IsolationScoreView] = []
        for item in items {
            views.append(toIsolationScoreView(item))
        }
        return views
    }

    static func sumIsolationScoreView(_ view: IsolationScoreView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedRefills)
    }
}
