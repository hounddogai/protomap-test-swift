import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range template.
    final class ReferenceRangeTemplateView {
        var codeText: String
        var title: String
        var createdAt: String
        var label: String
        var encounterIDText: String
        var statusLabel: String

        init(codeText: String, title: String, createdAt: String, label: String, encounterIDText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.createdAt = createdAt
            self.label = label
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeTemplateView(_ item: ReferenceRangeTemplate) -> ReferenceRangeTemplateView {
        return ReferenceRangeTemplateView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            createdAt: String(item.createdAt),
            label: item.label,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeTemplateViews(_ items: [ReferenceRangeTemplate]) -> [ReferenceRangeTemplateView] {
        var views: [ReferenceRangeTemplateView] = []
        for item in items {
            views.append(toReferenceRangeTemplateView(item))
        }
        return views
    }

    static func sumReferenceRangeTemplateView(_ view: ReferenceRangeTemplateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
