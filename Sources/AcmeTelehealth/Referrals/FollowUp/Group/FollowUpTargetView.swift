import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up target.
    final class FollowUpTargetView {
        var code: String
        var name: String
        var weight: String
        var clinicianID: String
        var maximumText: String
        var statusLabel: String

        init(code: String, name: String, weight: String, clinicianID: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.clinicianID = clinicianID
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpTargetView(_ item: FollowUpTarget) -> FollowUpTargetView {
        return FollowUpTargetView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            weight: String(format: "%.2f", item.weight),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpTargetViews(_ items: [FollowUpTarget]) -> [FollowUpTargetView] {
        var views: [FollowUpTargetView] = []
        for item in items {
            views.append(toFollowUpTargetView(item))
        }
        return views
    }

    static func sumFollowUpTargetView(_ view: FollowUpTargetView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedWeight + parsedMaximum
    }
}
