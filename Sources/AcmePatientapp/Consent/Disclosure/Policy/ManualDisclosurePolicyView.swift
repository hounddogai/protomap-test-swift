import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual disclosure policy.
    final class ManualDisclosurePolicyView {
        var code: String
        var title: String
        var ceiling: String
        var visible: String
        var description: String
        var segment: String
        var channel: String
        var revision: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, visible: String, description: String, segment: String, channel: String, revision: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.visible = visible
            self.description = description
            self.segment = segment
            self.channel = channel
            self.revision = revision
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toManualDisclosurePolicyView(_ item: ManualDisclosurePolicy) -> ManualDisclosurePolicyView {
        return ManualDisclosurePolicyView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            visible: "\(item.visible)",
            description: item.description,
            segment: item.segment,
            channel: item.channel,
            revision: String(item.revision),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDisclosurePolicyViews(_ items: [ManualDisclosurePolicy]) -> [ManualDisclosurePolicyView] {
        var views: [ManualDisclosurePolicyView] = []
        for item in items {
            views.append(toManualDisclosurePolicyView(item))
        }
        return views
    }

    static func sumManualDisclosurePolicyView(_ view: ManualDisclosurePolicyView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedCeiling + Double(parsedRevision)
    }
}
