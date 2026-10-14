import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist rollup.
    final class WorklistRollupView {
        var code: String
        var titleText: String
        var acuity: String
        var country: String
        var nameText: String
        var statusLabel: String

        init(code: String, titleText: String, acuity: String, country: String, nameText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.acuity = acuity
            self.country = country
            self.nameText = nameText
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistRollupView(_ item: WorklistRollup) -> WorklistRollupView {
        return WorklistRollupView(
            code: item.code,
            titleText: item.title,
            acuity: String(item.acuity),
            country: item.country,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistRollupViews(_ items: [WorklistRollup]) -> [WorklistRollupView] {
        var views: [WorklistRollupView] = []
        for item in items {
            views.append(toWorklistRollupView(item))
        }
        return views
    }

    static func sumWorklistRollupView(_ view: WorklistRollupView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
