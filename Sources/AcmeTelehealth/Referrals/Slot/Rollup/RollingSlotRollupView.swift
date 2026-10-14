import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling slot rollup.
    final class RollingSlotRollupView {
        var code: String
        var label: String
        var specialty: String
        var name: String
        var copay: String
        var priority: String
        var retriesText: String
        var ratio: String
        var visible: String
        var expiresAt: String
        var bedText: String
        var statusLabel: String

        init(code: String, label: String, specialty: String, name: String, copay: String, priority: String, retriesText: String, ratio: String, visible: String, expiresAt: String, bedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.name = name
            self.copay = copay
            self.priority = priority
            self.retriesText = retriesText
            self.ratio = ratio
            self.visible = visible
            self.expiresAt = expiresAt
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSlotRollupView(_ item: RollingSlotRollup) -> RollingSlotRollupView {
        return RollingSlotRollupView(
            code: item.code,
            label: item.label,
            specialty: item.specialty,
            name: Kit.Text.truncate(item.name, limit: 64),
            copay: String(format: "%.2f", item.copay),
            priority: String(item.priority),
            retriesText: String(item.retries),
            ratio: String(format: "%.2f", item.ratio),
            visible: "\(item.visible)",
            expiresAt: String(item.expiresAt),
            bedText: Kit.Text.truncate(item.bed, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSlotRollupViews(_ items: [RollingSlotRollup]) -> [RollingSlotRollupView] {
        var views: [RollingSlotRollupView] = []
        for item in items {
            views.append(toRollingSlotRollupView(item))
        }
        return views
    }

    static func sumRollingSlotRollupView(_ view: RollingSlotRollupView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedCopay + Double(parsedPriority) + Double(parsedRetries)
    }
}
