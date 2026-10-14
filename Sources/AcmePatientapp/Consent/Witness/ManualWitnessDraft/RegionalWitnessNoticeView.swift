import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional witness notice.
    final class RegionalWitnessNoticeView {
        var code: String
        var labelText: String
        var clinicianID: String
        var startsAtText: String
        var costText: String
        var acuity: String
        var discount: String
        var statusLabel: String

        init(code: String, labelText: String, clinicianID: String, startsAtText: String, costText: String, acuity: String, discount: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.clinicianID = clinicianID
            self.startsAtText = startsAtText
            self.costText = costText
            self.acuity = acuity
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalWitnessNoticeView(_ item: RegionalWitnessNotice) -> RegionalWitnessNoticeView {
        return RegionalWitnessNoticeView(
            code: item.code,
            labelText: item.label,
            clinicianID: item.clinicianID,
            startsAtText: String(item.startsAt),
            costText: String(format: "%.2f", item.cost),
            acuity: String(item.acuity),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalWitnessNoticeViews(_ items: [RegionalWitnessNotice]) -> [RegionalWitnessNoticeView] {
        var views: [RegionalWitnessNoticeView] = []
        for item in items {
            views.append(toRegionalWitnessNoticeView(item))
        }
        return views
    }

    static func sumRegionalWitnessNoticeView(_ view: RegionalWitnessNoticeView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedStartsAt) + parsedCost + Double(parsedAcuity)
    }
}
