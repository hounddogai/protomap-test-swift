import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan preference.
    final class DischargePlanPreferenceView {
        var codeText: String
        var name: String
        var sequence: String
        var title: String
        var discount: String
        var statusLabel: String

        init(codeText: String, name: String, sequence: String, title: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.sequence = sequence
            self.title = title
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanPreferenceView(_ item: DischargePlanPreference) -> DischargePlanPreferenceView {
        return DischargePlanPreferenceView(
            codeText: item.code,
            name: item.name,
            sequence: String(item.sequence),
            title: item.title,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanPreferenceViews(_ items: [DischargePlanPreference]) -> [DischargePlanPreferenceView] {
        var views: [DischargePlanPreferenceView] = []
        for item in items {
            views.append(toDischargePlanPreferenceView(item))
        }
        return views
    }

    static func sumDischargePlanPreferenceView(_ view: DischargePlanPreferenceView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedSequence) + parsedDiscount
    }
}
