import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual closure rollup.
    final class ManualClosureRollupView {
        var code: String
        var title: String
        var visitMinutes: String
        var bed: String
        var name: String
        var statusLabel: String

        init(code: String, title: String, visitMinutes: String, bed: String, name: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.bed = bed
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toManualClosureRollupView(_ item: ManualClosureRollup) -> ManualClosureRollupView {
        return ManualClosureRollupView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            visitMinutes: String(item.visitMinutes),
            bed: item.bed,
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualClosureRollupViews(_ items: [ManualClosureRollup]) -> [ManualClosureRollupView] {
        var views: [ManualClosureRollupView] = []
        for item in items {
            views.append(toManualClosureRollupView(item))
        }
        return views
    }

    static func sumManualClosureRollupView(_ view: ManualClosureRollupView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
