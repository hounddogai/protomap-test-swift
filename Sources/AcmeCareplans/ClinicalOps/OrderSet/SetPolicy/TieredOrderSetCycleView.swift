import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered order set cycle.
    final class TieredOrderSetCycleView {
        var codeText: String
        var label: String
        var version: String
        var archivedText: String
        var category: String
        var limitText: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, version: String, archivedText: String, category: String, limitText: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.version = version
            self.archivedText = archivedText
            self.category = category
            self.limitText = limitText
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toTieredOrderSetCycleView(_ item: TieredOrderSetCycle) -> TieredOrderSetCycleView {
        return TieredOrderSetCycleView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            version: String(item.version),
            archivedText: "\(item.archived)",
            category: Kit.Text.truncate(item.category, limit: 64),
            limitText: String(item.limit),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredOrderSetCycleViews(_ items: [TieredOrderSetCycle]) -> [TieredOrderSetCycleView] {
        var views: [TieredOrderSetCycleView] = []
        for item in items {
            views.append(toTieredOrderSetCycleView(item))
        }
        return views
    }

    static func sumTieredOrderSetCycleView(_ view: TieredOrderSetCycleView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVersion) + Double(parsedLimit) + Double(parsedVisitMinutes)
    }
}
