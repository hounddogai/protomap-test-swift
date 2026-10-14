import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered care gap schedule.
    final class TieredCareGapScheduleView {
        var code: String
        var label: String
        var minimum: String
        var checksum: String
        var priority: String
        var ratio: String
        var contactEmail: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, minimum: String, checksum: String, priority: String, ratio: String, contactEmail: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.checksum = checksum
            self.priority = priority
            self.ratio = ratio
            self.contactEmail = contactEmail
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCareGapScheduleView(_ item: TieredCareGapSchedule) -> TieredCareGapScheduleView {
        return TieredCareGapScheduleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            priority: String(item.priority),
            ratio: String(format: "%.2f", item.ratio),
            contactEmail: item.contactEmail,
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCareGapScheduleViews(_ items: [TieredCareGapSchedule]) -> [TieredCareGapScheduleView] {
        var views: [TieredCareGapScheduleView] = []
        for item in items {
            views.append(toTieredCareGapScheduleView(item))
        }
        return views
    }

    static func sumTieredCareGapScheduleView(_ view: TieredCareGapScheduleView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMinimum + Double(parsedPriority) + parsedRatio
    }
}
