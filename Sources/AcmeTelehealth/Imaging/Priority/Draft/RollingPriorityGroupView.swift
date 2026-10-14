import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling priority group.
    final class RollingPriorityGroupView {
        var codeText: String
        var title: String
        var checksum: String
        var weight: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, title: String, checksum: String, weight: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.checksum = checksum
            self.weight = weight
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPriorityGroupView(_ item: RollingPriorityGroup) -> RollingPriorityGroupView {
        return RollingPriorityGroupView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            checksum: item.checksum,
            weight: String(format: "%.2f", item.weight),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPriorityGroupViews(_ items: [RollingPriorityGroup]) -> [RollingPriorityGroupView] {
        var views: [RollingPriorityGroupView] = []
        for item in items {
            views.append(toRollingPriorityGroupView(item))
        }
        return views
    }

    static func sumRollingPriorityGroupView(_ view: RollingPriorityGroupView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
