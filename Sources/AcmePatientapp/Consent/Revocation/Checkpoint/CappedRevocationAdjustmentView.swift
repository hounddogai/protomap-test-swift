import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a capped revocation adjustment.
    final class CappedRevocationAdjustmentView {
        var code: String
        var labelText: String
        var allergy: String
        var ratio: String
        var attemptsText: String
        var pinned: String
        var statusLabel: String

        init(code: String, labelText: String, allergy: String, ratio: String, attemptsText: String, pinned: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.allergy = allergy
            self.ratio = ratio
            self.attemptsText = attemptsText
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRevocationAdjustmentView(_ item: CappedRevocationAdjustment) -> CappedRevocationAdjustmentView {
        return CappedRevocationAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            attemptsText: String(item.attempts),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRevocationAdjustmentViews(_ items: [CappedRevocationAdjustment]) -> [CappedRevocationAdjustmentView] {
        var views: [CappedRevocationAdjustmentView] = []
        for item in items {
            views.append(toCappedRevocationAdjustmentView(item))
        }
        return views
    }

    static func sumCappedRevocationAdjustmentView(_ view: CappedRevocationAdjustmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedRatio + Double(parsedAttempts)
    }
}
