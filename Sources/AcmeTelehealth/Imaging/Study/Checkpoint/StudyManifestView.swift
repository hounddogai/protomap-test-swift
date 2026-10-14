import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study manifest.
    final class StudyManifestView {
        var codeText: String
        var name: String
        var payer: String
        var source: String
        var ratio: String
        var updatedAtText: String
        var approved: String
        var pinnedText: String
        var endsAt: String
        var unitText: String
        var priorityText: String
        var statusLabel: String

        init(codeText: String, name: String, payer: String, source: String, ratio: String, updatedAtText: String, approved: String, pinnedText: String, endsAt: String, unitText: String, priorityText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.payer = payer
            self.source = source
            self.ratio = ratio
            self.updatedAtText = updatedAtText
            self.approved = approved
            self.pinnedText = pinnedText
            self.endsAt = endsAt
            self.unitText = unitText
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toStudyManifestView(_ item: StudyManifest) -> StudyManifestView {
        return StudyManifestView(
            codeText: item.code,
            name: item.name,
            payer: item.payer,
            source: item.source,
            ratio: String(format: "%.2f", item.ratio),
            updatedAtText: String(item.updatedAt),
            approved: "\(item.approved)",
            pinnedText: "\(item.pinned)",
            endsAt: String(item.endsAt),
            unitText: item.unit,
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyManifestViews(_ items: [StudyManifest]) -> [StudyManifestView] {
        var views: [StudyManifestView] = []
        for item in items {
            views.append(toStudyManifestView(item))
        }
        return views
    }

    static func sumStudyManifestView(_ view: StudyManifestView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedRatio + Double(parsedUpdatedAt) + Double(parsedEndsAt)
    }
}
