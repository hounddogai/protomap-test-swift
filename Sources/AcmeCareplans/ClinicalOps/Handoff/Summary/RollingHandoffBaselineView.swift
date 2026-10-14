import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling handoff baseline.
    final class RollingHandoffBaselineView {
        var code: String
        var name: String
        var externalRef: String
        var checksum: String
        var capacity: String
        var weight: String
        var windowDays: String
        var retriesText: String
        var graceDays: String
        var statusLabel: String

        init(code: String, name: String, externalRef: String, checksum: String, capacity: String, weight: String, windowDays: String, retriesText: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.checksum = checksum
            self.capacity = capacity
            self.weight = weight
            self.windowDays = windowDays
            self.retriesText = retriesText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toRollingHandoffBaselineView(_ item: RollingHandoffBaseline) -> RollingHandoffBaselineView {
        return RollingHandoffBaselineView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            externalRef: item.externalRef,
            checksum: item.checksum,
            capacity: String(item.capacity),
            weight: String(format: "%.2f", item.weight),
            windowDays: String(item.windowDays),
            retriesText: String(item.retries),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingHandoffBaselineViews(_ items: [RollingHandoffBaseline]) -> [RollingHandoffBaselineView] {
        var views: [RollingHandoffBaselineView] = []
        for item in items {
            views.append(toRollingHandoffBaselineView(item))
        }
        return views
    }

    static func sumRollingHandoffBaselineView(_ view: RollingHandoffBaselineView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedCapacity) + parsedWeight + Double(parsedWindowDays)
    }
}
