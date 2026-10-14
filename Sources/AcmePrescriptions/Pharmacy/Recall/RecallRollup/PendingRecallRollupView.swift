import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending recall rollup.
    final class PendingRecallRollupView {
        var code: String
        var title: String
        var sequence: String
        var durationMinutes: String
        var locale: String
        var statusLabel: String

        init(code: String, title: String, sequence: String, durationMinutes: String, locale: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.durationMinutes = durationMinutes
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRecallRollupView(_ item: PendingRecallRollup) -> PendingRecallRollupView {
        return PendingRecallRollupView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            sequence: String(item.sequence),
            durationMinutes: String(item.durationMinutes),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRecallRollupViews(_ items: [PendingRecallRollup]) -> [PendingRecallRollupView] {
        var views: [PendingRecallRollupView] = []
        for item in items {
            views.append(toPendingRecallRollupView(item))
        }
        return views
    }

    static func sumPendingRecallRollupView(_ view: PendingRecallRollupView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedSequence) + Double(parsedDurationMinutes)
    }
}
