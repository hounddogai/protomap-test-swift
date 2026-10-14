import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive shift policy.
    final class AdaptiveShiftPolicyView {
        var code: String
        var nameText: String
        var archived: String
        var payer: String
        var expiresAt: String
        var minimum: String
        var statusLabel: String

        init(code: String, nameText: String, archived: String, payer: String, expiresAt: String, minimum: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.archived = archived
            self.payer = payer
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveShiftPolicyView(_ item: AdaptiveShiftPolicy) -> AdaptiveShiftPolicyView {
        return AdaptiveShiftPolicyView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            archived: "\(item.archived)",
            payer: item.payer,
            expiresAt: String(item.expiresAt),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveShiftPolicyViews(_ items: [AdaptiveShiftPolicy]) -> [AdaptiveShiftPolicyView] {
        var views: [AdaptiveShiftPolicyView] = []
        for item in items {
            views.append(toAdaptiveShiftPolicyView(item))
        }
        return views
    }

    static func sumAdaptiveShiftPolicyView(_ view: AdaptiveShiftPolicyView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedExpiresAt) + parsedMinimum
    }
}
