import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge tier.
    final class ChargeTierView {
        var code: String
        var nameText: String
        var endsAt: String
        var revisionText: String
        var floorValue: String
        var acuity: String
        var statusLabel: String

        init(code: String, nameText: String, endsAt: String, revisionText: String, floorValue: String, acuity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.endsAt = endsAt
            self.revisionText = revisionText
            self.floorValue = floorValue
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toChargeTierView(_ item: ChargeTier) -> ChargeTierView {
        return ChargeTierView(
            code: item.code,
            nameText: item.name,
            endsAt: String(item.endsAt),
            revisionText: String(item.revision),
            floorValue: String(format: "%.2f", item.floorValue),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeTierViews(_ items: [ChargeTier]) -> [ChargeTierView] {
        var views: [ChargeTierView] = []
        for item in items {
            views.append(toChargeTierView(item))
        }
        return views
    }

    static func sumChargeTierView(_ view: ChargeTierView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedRevision) + parsedFloorValue
    }
}
