import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual census allocation.
    final class ManualCensusAllocationView {
        var code: String
        var title: String
        var retries: String
        var channel: String
        var windowDays: String
        var weight: String
        var reviewer: String
        var statusLabel: String

        init(code: String, title: String, retries: String, channel: String, windowDays: String, weight: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.retries = retries
            self.channel = channel
            self.windowDays = windowDays
            self.weight = weight
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toManualCensusAllocationView(_ item: ManualCensusAllocation) -> ManualCensusAllocationView {
        return ManualCensusAllocationView(
            code: item.code,
            title: item.title,
            retries: String(item.retries),
            channel: item.channel,
            windowDays: String(item.windowDays),
            weight: String(format: "%.2f", item.weight),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCensusAllocationViews(_ items: [ManualCensusAllocation]) -> [ManualCensusAllocationView] {
        var views: [ManualCensusAllocationView] = []
        for item in items {
            views.append(toManualCensusAllocationView(item))
        }
        return views
    }

    static func sumManualCensusAllocationView(_ view: ManualCensusAllocationView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedRetries) + Double(parsedWindowDays) + parsedWeight
    }
}
