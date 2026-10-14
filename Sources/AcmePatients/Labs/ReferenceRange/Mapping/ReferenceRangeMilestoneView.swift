import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range milestone.
    final class ReferenceRangeMilestoneView {
        var code: String
        var label: String
        var dosageMg: String
        var unit: String
        var marginText: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, dosageMg: String, unit: String, marginText: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.unit = unit
            self.marginText = marginText
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeMilestoneView(_ item: ReferenceRangeMilestone) -> ReferenceRangeMilestoneView {
        return ReferenceRangeMilestoneView(
            code: item.code,
            label: item.label,
            dosageMg: String(format: "%.2f", item.dosageMg),
            unit: item.unit,
            marginText: String(format: "%.2f", item.margin),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeMilestoneViews(_ items: [ReferenceRangeMilestone]) -> [ReferenceRangeMilestoneView] {
        var views: [ReferenceRangeMilestoneView] = []
        for item in items {
            views.append(toReferenceRangeMilestoneView(item))
        }
        return views
    }

    static func sumReferenceRangeMilestoneView(_ view: ReferenceRangeMilestoneView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedDosageMg + parsedMargin
    }
}
