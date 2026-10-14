import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual discharge plan target.
    final class ManualDischargePlanTargetView {
        var code: String
        var label: String
        var attempts: String
        var refills: String
        var country: String
        var updatedAtText: String
        var minimumText: String
        var ratio: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, attempts: String, refills: String, country: String, updatedAtText: String, minimumText: String, ratio: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.refills = refills
            self.country = country
            self.updatedAtText = updatedAtText
            self.minimumText = minimumText
            self.ratio = ratio
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toManualDischargePlanTargetView(_ item: ManualDischargePlanTarget) -> ManualDischargePlanTargetView {
        return ManualDischargePlanTargetView(
            code: item.code,
            label: item.label,
            attempts: String(item.attempts),
            refills: String(item.refills),
            country: Kit.Text.truncate(item.country, limit: 80),
            updatedAtText: String(item.updatedAt),
            minimumText: String(format: "%.2f", item.minimum),
            ratio: String(format: "%.2f", item.ratio),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDischargePlanTargetViews(_ items: [ManualDischargePlanTarget]) -> [ManualDischargePlanTargetView] {
        var views: [ManualDischargePlanTargetView] = []
        for item in items {
            views.append(toManualDischargePlanTargetView(item))
        }
        return views
    }

    static func sumManualDischargePlanTargetView(_ view: ManualDischargePlanTargetView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedRefills) + Double(parsedUpdatedAt)
    }
}
