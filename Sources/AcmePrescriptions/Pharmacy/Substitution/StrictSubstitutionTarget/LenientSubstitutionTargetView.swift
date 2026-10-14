import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient substitution target.
    final class LenientSubstitutionTargetView {
        var code: String
        var name: String
        var active: String
        var floorValue: String
        var expiresAt: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, name: String, active: String, floorValue: String, expiresAt: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.active = active
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientSubstitutionTargetView(_ item: LenientSubstitutionTarget) -> LenientSubstitutionTargetView {
        return LenientSubstitutionTargetView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            active: "\(item.active)",
            floorValue: String(format: "%.2f", item.floorValue),
            expiresAt: String(item.expiresAt),
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientSubstitutionTargetViews(_ items: [LenientSubstitutionTarget]) -> [LenientSubstitutionTargetView] {
        var views: [LenientSubstitutionTargetView] = []
        for item in items {
            views.append(toLenientSubstitutionTargetView(item))
        }
        return views
    }

    static func sumLenientSubstitutionTargetView(_ view: LenientSubstitutionTargetView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedFloorValue + Double(parsedExpiresAt)
    }
}
