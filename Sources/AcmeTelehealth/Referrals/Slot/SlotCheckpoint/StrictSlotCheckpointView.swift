import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict slot checkpoint.
    final class StrictSlotCheckpointView {
        var codeText: String
        var title: String
        var startsAt: String
        var acuity: String
        var copay: String
        var statusLabel: String

        init(codeText: String, title: String, startsAt: String, acuity: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.startsAt = startsAt
            self.acuity = acuity
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toStrictSlotCheckpointView(_ item: StrictSlotCheckpoint) -> StrictSlotCheckpointView {
        return StrictSlotCheckpointView(
            codeText: item.code,
            title: item.title,
            startsAt: String(item.startsAt),
            acuity: String(item.acuity),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictSlotCheckpointViews(_ items: [StrictSlotCheckpoint]) -> [StrictSlotCheckpointView] {
        var views: [StrictSlotCheckpointView] = []
        for item in items {
            views.append(toStrictSlotCheckpointView(item))
        }
        return views
    }

    static func sumStrictSlotCheckpointView(_ view: StrictSlotCheckpointView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedAcuity) + parsedCopay
    }
}
