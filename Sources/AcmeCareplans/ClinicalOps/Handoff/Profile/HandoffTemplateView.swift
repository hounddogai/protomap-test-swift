import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff template.
    final class HandoffTemplateView {
        var code: String
        var name: String
        var reviewer: String
        var revision: String
        var channel: String
        var statusLabel: String

        init(code: String, name: String, reviewer: String, revision: String, channel: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.revision = revision
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffTemplateView(_ item: HandoffTemplate) -> HandoffTemplateView {
        return HandoffTemplateView(
            code: item.code,
            name: item.name,
            reviewer: item.reviewer,
            revision: String(item.revision),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffTemplateViews(_ items: [HandoffTemplate]) -> [HandoffTemplateView] {
        var views: [HandoffTemplateView] = []
        for item in items {
            views.append(toHandoffTemplateView(item))
        }
        return views
    }

    static func sumHandoffTemplateView(_ view: HandoffTemplateView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
