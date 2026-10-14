import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range rollup.
    final class ReferenceRangeRollupView {
        var code: String
        var label: String
        var title: String
        var acuity: String
        var unit: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, title: String, acuity: String, unit: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.title = title
            self.acuity = acuity
            self.unit = unit
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeRollupView(_ item: ReferenceRangeRollup) -> ReferenceRangeRollupView {
        return ReferenceRangeRollupView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 64),
            acuity: String(item.acuity),
            unit: item.unit,
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeRollupViews(_ items: [ReferenceRangeRollup]) -> [ReferenceRangeRollupView] {
        var views: [ReferenceRangeRollupView] = []
        for item in items {
            views.append(toReferenceRangeRollupView(item))
        }
        return views
    }

    static func sumReferenceRangeRollupView(_ view: ReferenceRangeRollupView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedUpdatedAt)
    }
}
