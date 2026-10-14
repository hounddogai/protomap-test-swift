import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending recall cycle.
    final class PendingRecallCycleView {
        var code: String
        var title: String
        var currency: String
        var minimum: String
        var graceDaysText: String
        var segment: String
        var phoneText: String
        var reviewer: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, title: String, currency: String, minimum: String, graceDaysText: String, segment: String, phoneText: String, reviewer: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.currency = currency
            self.minimum = minimum
            self.graceDaysText = graceDaysText
            self.segment = segment
            self.phoneText = phoneText
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRecallCycleView(_ item: PendingRecallCycle) -> PendingRecallCycleView {
        return PendingRecallCycleView(
            code: item.code,
            title: item.title,
            currency: Kit.Text.truncate(item.currency, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            graceDaysText: String(item.graceDays),
            segment: item.segment,
            phoneText: Kit.Text.truncate(item.phone, limit: 64),
            reviewer: item.reviewer,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRecallCycleViews(_ items: [PendingRecallCycle]) -> [PendingRecallCycleView] {
        var views: [PendingRecallCycleView] = []
        for item in items {
            views.append(toPendingRecallCycleView(item))
        }
        return views
    }

    static func sumPendingRecallCycleView(_ view: PendingRecallCycleView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMinimum + Double(parsedGraceDays) + Double(parsedDurationMinutes)
    }
}
