import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback network checkpoint.
    final class FallbackNetworkCheckpointView {
        var code: String
        var labelText: String
        var priority: String
        var patientRef: String
        var cost: String
        var rate: String
        var region: String
        var statusLabel: String

        init(code: String, labelText: String, priority: String, patientRef: String, cost: String, rate: String, region: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.priority = priority
            self.patientRef = patientRef
            self.cost = cost
            self.rate = rate
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackNetworkCheckpointView(_ item: FallbackNetworkCheckpoint) -> FallbackNetworkCheckpointView {
        return FallbackNetworkCheckpointView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            priority: String(item.priority),
            patientRef: item.patientRef,
            cost: String(format: "%.2f", item.cost),
            rate: String(format: "%.2f", item.rate),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackNetworkCheckpointViews(_ items: [FallbackNetworkCheckpoint]) -> [FallbackNetworkCheckpointView] {
        var views: [FallbackNetworkCheckpointView] = []
        for item in items {
            views.append(toFallbackNetworkCheckpointView(item))
        }
        return views
    }

    static func sumFallbackNetworkCheckpointView(_ view: FallbackNetworkCheckpointView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedPriority) + parsedCost + parsedRate
    }
}
