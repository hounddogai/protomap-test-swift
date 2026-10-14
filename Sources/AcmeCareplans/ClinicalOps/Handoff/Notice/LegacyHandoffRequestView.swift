import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy handoff request.
    final class LegacyHandoffRequestView {
        var codeText: String
        var label: String
        var graceDays: String
        var minimumText: String
        var startsAt: String
        var archived: String
        var statusLabel: String

        init(codeText: String, label: String, graceDays: String, minimumText: String, startsAt: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.graceDays = graceDays
            self.minimumText = minimumText
            self.startsAt = startsAt
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyHandoffRequestView(_ item: LegacyHandoffRequest) -> LegacyHandoffRequestView {
        return LegacyHandoffRequestView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            graceDays: String(item.graceDays),
            minimumText: String(format: "%.2f", item.minimum),
            startsAt: String(item.startsAt),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyHandoffRequestViews(_ items: [LegacyHandoffRequest]) -> [LegacyHandoffRequestView] {
        var views: [LegacyHandoffRequestView] = []
        for item in items {
            views.append(toLegacyHandoffRequestView(item))
        }
        return views
    }

    static func sumLegacyHandoffRequestView(_ view: LegacyHandoffRequestView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedGraceDays) + parsedMinimum + Double(parsedStartsAt)
    }
}
