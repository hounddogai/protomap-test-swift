import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global disclosure request.
    final class GlobalDisclosureRequestView {
        var code: String
        var title: String
        var score: String
        var procedureCode: String
        var endsAtText: String
        var reviewer: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, score: String, procedureCode: String, endsAtText: String, reviewer: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.score = score
            self.procedureCode = procedureCode
            self.endsAtText = endsAtText
            self.reviewer = reviewer
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDisclosureRequestView(_ item: GlobalDisclosureRequest) -> GlobalDisclosureRequestView {
        return GlobalDisclosureRequestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            score: String(format: "%.2f", item.score),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            endsAtText: String(item.endsAt),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDisclosureRequestViews(_ items: [GlobalDisclosureRequest]) -> [GlobalDisclosureRequestView] {
        var views: [GlobalDisclosureRequestView] = []
        for item in items {
            views.append(toGlobalDisclosureRequestView(item))
        }
        return views
    }

    static func sumGlobalDisclosureRequestView(_ view: GlobalDisclosureRequestView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedScore + Double(parsedEndsAt) + Double(parsedRefills)
    }
}
