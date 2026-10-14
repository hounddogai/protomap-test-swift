import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime rollup.
    final class OvertimeRollupView {
        var code: String
        var title: String
        var label: String
        var wardText: String
        var batchSizeText: String
        var endsAt: String
        var startsAt: String
        var windowDays: String
        var name: String
        var statusLabel: String

        init(code: String, title: String, label: String, wardText: String, batchSizeText: String, endsAt: String, startsAt: String, windowDays: String, name: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.label = label
            self.wardText = wardText
            self.batchSizeText = batchSizeText
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.windowDays = windowDays
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeRollupView(_ item: OvertimeRollup) -> OvertimeRollupView {
        return OvertimeRollupView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            label: item.label,
            wardText: item.ward,
            batchSizeText: String(item.batchSize),
            endsAt: String(item.endsAt),
            startsAt: String(item.startsAt),
            windowDays: String(item.windowDays),
            name: Kit.Text.truncate(item.name, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeRollupViews(_ items: [OvertimeRollup]) -> [OvertimeRollupView] {
        var views: [OvertimeRollupView] = []
        for item in items {
            views.append(toOvertimeRollupView(item))
        }
        return views
    }

    static func sumOvertimeRollupView(_ view: OvertimeRollupView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedEndsAt) + Double(parsedStartsAt)
    }
}
