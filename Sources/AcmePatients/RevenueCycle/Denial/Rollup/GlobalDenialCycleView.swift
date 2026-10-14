import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global denial cycle.
    final class GlobalDenialCycleView {
        var codeText: String
        var name: String
        var maximum: String
        var encounterIDText: String
        var ownerID: String
        var updatedAt: String
        var retriesText: String
        var statusLabel: String

        init(codeText: String, name: String, maximum: String, encounterIDText: String, ownerID: String, updatedAt: String, retriesText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.maximum = maximum
            self.encounterIDText = encounterIDText
            self.ownerID = ownerID
            self.updatedAt = updatedAt
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDenialCycleView(_ item: GlobalDenialCycle) -> GlobalDenialCycleView {
        return GlobalDenialCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            encounterIDText: item.encounterID,
            ownerID: item.ownerID,
            updatedAt: String(item.updatedAt),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDenialCycleViews(_ items: [GlobalDenialCycle]) -> [GlobalDenialCycleView] {
        var views: [GlobalDenialCycleView] = []
        for item in items {
            views.append(toGlobalDenialCycleView(item))
        }
        return views
    }

    static func sumGlobalDenialCycleView(_ view: GlobalDenialCycleView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedMaximum + Double(parsedUpdatedAt) + Double(parsedRetries)
    }
}
