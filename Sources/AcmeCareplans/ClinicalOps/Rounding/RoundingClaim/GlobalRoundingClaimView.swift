import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global rounding claim.
    final class GlobalRoundingClaimView {
        var codeText: String
        var label: String
        var attempts: String
        var floorValueText: String
        var ownerIDText: String
        var ratioText: String
        var weightText: String
        var currency: String
        var statusLabel: String

        init(codeText: String, label: String, attempts: String, floorValueText: String, ownerIDText: String, ratioText: String, weightText: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.attempts = attempts
            self.floorValueText = floorValueText
            self.ownerIDText = ownerIDText
            self.ratioText = ratioText
            self.weightText = weightText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalRoundingClaimView(_ item: GlobalRoundingClaim) -> GlobalRoundingClaimView {
        return GlobalRoundingClaimView(
            codeText: item.code,
            label: item.label,
            attempts: String(item.attempts),
            floorValueText: String(format: "%.2f", item.floorValue),
            ownerIDText: item.ownerID,
            ratioText: String(format: "%.2f", item.ratio),
            weightText: String(format: "%.2f", item.weight),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalRoundingClaimViews(_ items: [GlobalRoundingClaim]) -> [GlobalRoundingClaimView] {
        var views: [GlobalRoundingClaimView] = []
        for item in items {
            views.append(toGlobalRoundingClaimView(item))
        }
        return views
    }

    static func sumGlobalRoundingClaimView(_ view: GlobalRoundingClaimView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedAttempts) + parsedFloorValue + parsedRatio
    }
}
