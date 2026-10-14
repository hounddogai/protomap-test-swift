import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled accession target.
    final class ScheduledAccessionTargetView {
        var code: String
        var label: String
        var createdAt: String
        var cost: String
        var segment: String
        var maximumText: String
        var ceiling: String
        var notes: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, cost: String, segment: String, maximumText: String, ceiling: String, notes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.cost = cost
            self.segment = segment
            self.maximumText = maximumText
            self.ceiling = ceiling
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAccessionTargetView(_ item: ScheduledAccessionTarget) -> ScheduledAccessionTargetView {
        return ScheduledAccessionTargetView(
            code: item.code,
            label: item.label,
            createdAt: String(item.createdAt),
            cost: String(format: "%.2f", item.cost),
            segment: item.segment,
            maximumText: String(format: "%.2f", item.maximum),
            ceiling: String(format: "%.2f", item.ceiling),
            notes: Kit.Text.truncate(item.notes, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAccessionTargetViews(_ items: [ScheduledAccessionTarget]) -> [ScheduledAccessionTargetView] {
        var views: [ScheduledAccessionTargetView] = []
        for item in items {
            views.append(toScheduledAccessionTargetView(item))
        }
        return views
    }

    static func sumScheduledAccessionTargetView(_ view: ScheduledAccessionTargetView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedCreatedAt) + parsedCost + parsedMaximum
    }
}
