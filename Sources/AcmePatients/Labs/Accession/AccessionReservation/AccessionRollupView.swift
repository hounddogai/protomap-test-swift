import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession rollup.
    final class AccessionRollupView {
        var codeText: String
        var nameText: String
        var discount: String
        var encounterIDText: String
        var segmentText: String
        var phone: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, nameText: String, discount: String, encounterIDText: String, segmentText: String, phone: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.discount = discount
            self.encounterIDText = encounterIDText
            self.segmentText = segmentText
            self.phone = phone
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionRollupView(_ item: AccessionRollup) -> AccessionRollupView {
        return AccessionRollupView(
            codeText: item.code,
            nameText: item.name,
            discount: String(format: "%.2f", item.discount),
            encounterIDText: item.encounterID,
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            phone: item.phone,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionRollupViews(_ items: [AccessionRollup]) -> [AccessionRollupView] {
        var views: [AccessionRollupView] = []
        for item in items {
            views.append(toAccessionRollupView(item))
        }
        return views
    }

    static func sumAccessionRollupView(_ view: AccessionRollupView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDiscount + Double(parsedStartsAt)
    }
}
