import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient worklist template.
    final class LenientWorklistTemplateView {
        var code: String
        var label: String
        var allergy: String
        var summary: String
        var bed: String
        var archived: String
        var version: String
        var statusLabel: String

        init(code: String, label: String, allergy: String, summary: String, bed: String, archived: String, version: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.summary = summary
            self.bed = bed
            self.archived = archived
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toLenientWorklistTemplateView(_ item: LenientWorklistTemplate) -> LenientWorklistTemplateView {
        return LenientWorklistTemplateView(
            code: item.code,
            label: item.label,
            allergy: item.allergy,
            summary: item.summary,
            bed: item.bed,
            archived: "\(item.archived)",
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientWorklistTemplateViews(_ items: [LenientWorklistTemplate]) -> [LenientWorklistTemplateView] {
        var views: [LenientWorklistTemplateView] = []
        for item in items {
            views.append(toLenientWorklistTemplateView(item))
        }
        return views
    }

    static func sumLenientWorklistTemplateView(_ view: LenientWorklistTemplateView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
