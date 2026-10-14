import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial baseline.
    final class DenialBaselineView {
        var code: String
        var label: String
        var summary: String
        var revision: String
        var visible: String
        var capacityText: String
        var externalRef: String
        var maximum: String
        var titleText: String
        var active: String
        var statusLabel: String

        init(code: String, label: String, summary: String, revision: String, visible: String, capacityText: String, externalRef: String, maximum: String, titleText: String, active: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summary = summary
            self.revision = revision
            self.visible = visible
            self.capacityText = capacityText
            self.externalRef = externalRef
            self.maximum = maximum
            self.titleText = titleText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toDenialBaselineView(_ item: DenialBaseline) -> DenialBaselineView {
        return DenialBaselineView(
            code: item.code,
            label: item.label,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            revision: String(item.revision),
            visible: "\(item.visible)",
            capacityText: String(item.capacity),
            externalRef: item.externalRef,
            maximum: String(format: "%.2f", item.maximum),
            titleText: item.title,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialBaselineViews(_ items: [DenialBaseline]) -> [DenialBaselineView] {
        var views: [DenialBaselineView] = []
        for item in items {
            views.append(toDenialBaselineView(item))
        }
        return views
    }

    static func sumDenialBaselineView(_ view: DenialBaselineView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedRevision) + Double(parsedCapacity) + parsedMaximum
    }
}
