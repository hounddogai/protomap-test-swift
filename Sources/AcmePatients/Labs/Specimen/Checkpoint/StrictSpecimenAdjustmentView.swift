import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a strict specimen adjustment.
    final class StrictSpecimenAdjustmentView {
        var code: String
        var name: String
        var contactEmail: String
        var startsAt: String
        var statusLabel: String

        init(code: String, name: String, contactEmail: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSpecimenAdjustmentView(_ item: StrictSpecimenAdjustment) -> StrictSpecimenAdjustmentView {
        return StrictSpecimenAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            contactEmail: item.contactEmail,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSpecimenAdjustmentViews(_ items: [StrictSpecimenAdjustment]) -> [StrictSpecimenAdjustmentView] {
        var views: [StrictSpecimenAdjustmentView] = []
        for item in items {
            views.append(toStrictSpecimenAdjustmentView(item))
        }
        return views
    }

    static func sumStrictSpecimenAdjustmentView(_ view: StrictSpecimenAdjustmentView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
