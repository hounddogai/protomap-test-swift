import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift checkpoint.
    final class ShiftCheckpointView {
        var code: String
        var label: String
        var segment: String
        var endsAt: String
        var description: String
        var margin: String
        var threshold: String
        var currency: String
        var pinned: String
        var statusLabel: String

        init(code: String, label: String, segment: String, endsAt: String, description: String, margin: String, threshold: String, currency: String, pinned: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segment = segment
            self.endsAt = endsAt
            self.description = description
            self.margin = margin
            self.threshold = threshold
            self.currency = currency
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toShiftCheckpointView(_ item: ShiftCheckpoint) -> ShiftCheckpointView {
        return ShiftCheckpointView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            segment: item.segment,
            endsAt: String(item.endsAt),
            description: item.description,
            margin: String(format: "%.2f", item.margin),
            threshold: String(format: "%.2f", item.threshold),
            currency: item.currency,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftCheckpointViews(_ items: [ShiftCheckpoint]) -> [ShiftCheckpointView] {
        var views: [ShiftCheckpointView] = []
        for item in items {
            views.append(toShiftCheckpointView(item))
        }
        return views
    }

    static func sumShiftCheckpointView(_ view: ShiftCheckpointView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedEndsAt) + parsedMargin + parsedThreshold
    }
}
