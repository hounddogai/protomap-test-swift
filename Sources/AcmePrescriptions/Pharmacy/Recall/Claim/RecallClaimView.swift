import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall claim.
    final class RecallClaimView {
        var code: String
        var nameText: String
        var segment: String
        var encounterIDText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, nameText: String, segment: String, encounterIDText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.segment = segment
            self.encounterIDText = encounterIDText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toRecallClaimView(_ item: RecallClaim) -> RecallClaimView {
        return RecallClaimView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            segment: item.segment,
            encounterIDText: item.encounterID,
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallClaimViews(_ items: [RecallClaim]) -> [RecallClaimView] {
        var views: [RecallClaimView] = []
        for item in items {
            views.append(toRecallClaimView(item))
        }
        return views
    }

    static func sumRecallClaimView(_ view: RecallClaimView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
