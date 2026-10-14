import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted substitution allocation.
    final class WeightedSubstitutionAllocationView {
        var code: String
        var title: String
        var discount: String
        var source: String
        var startsAtText: String
        var patientRef: String
        var statusLabel: String

        init(code: String, title: String, discount: String, source: String, startsAtText: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.discount = discount
            self.source = source
            self.startsAtText = startsAtText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSubstitutionAllocationView(_ item: WeightedSubstitutionAllocation) -> WeightedSubstitutionAllocationView {
        return WeightedSubstitutionAllocationView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            discount: String(format: "%.2f", item.discount),
            source: item.source,
            startsAtText: String(item.startsAt),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSubstitutionAllocationViews(_ items: [WeightedSubstitutionAllocation]) -> [WeightedSubstitutionAllocationView] {
        var views: [WeightedSubstitutionAllocationView] = []
        for item in items {
            views.append(toWeightedSubstitutionAllocationView(item))
        }
        return views
    }

    static func sumWeightedSubstitutionAllocationView(_ view: WeightedSubstitutionAllocationView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDiscount + Double(parsedStartsAt)
    }
}
