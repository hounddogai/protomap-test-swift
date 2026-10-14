import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive cleaning reservation.
    final class AdaptiveCleaningReservationView {
        var code: String
        var name: String
        var rate: String
        var batchSizeText: String
        var updatedAt: String
        var channel: String
        var segment: String
        var title: String
        var active: String
        var statusLabel: String

        init(code: String, name: String, rate: String, batchSizeText: String, updatedAt: String, channel: String, segment: String, title: String, active: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.rate = rate
            self.batchSizeText = batchSizeText
            self.updatedAt = updatedAt
            self.channel = channel
            self.segment = segment
            self.title = title
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCleaningReservationView(_ item: AdaptiveCleaningReservation) -> AdaptiveCleaningReservationView {
        return AdaptiveCleaningReservationView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            rate: String(format: "%.2f", item.rate),
            batchSizeText: String(item.batchSize),
            updatedAt: String(item.updatedAt),
            channel: item.channel,
            segment: item.segment,
            title: item.title,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCleaningReservationViews(_ items: [AdaptiveCleaningReservation]) -> [AdaptiveCleaningReservationView] {
        var views: [AdaptiveCleaningReservationView] = []
        for item in items {
            views.append(toAdaptiveCleaningReservationView(item))
        }
        return views
    }

    static func sumAdaptiveCleaningReservationView(_ view: AdaptiveCleaningReservationView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedRate + Double(parsedBatchSize) + Double(parsedUpdatedAt)
    }
}
