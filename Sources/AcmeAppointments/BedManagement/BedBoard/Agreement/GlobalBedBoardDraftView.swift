import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global bed board draft.
    final class GlobalBedBoardDraftView {
        var codeText: String
        var labelText: String
        var margin: String
        var ratio: String
        var updatedAtText: String
        var allergy: String
        var summary: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, labelText: String, margin: String, ratio: String, updatedAtText: String, allergy: String, summary: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.margin = margin
            self.ratio = ratio
            self.updatedAtText = updatedAtText
            self.allergy = allergy
            self.summary = summary
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalBedBoardDraftView(_ item: GlobalBedBoardDraft) -> GlobalBedBoardDraftView {
        return GlobalBedBoardDraftView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            margin: String(format: "%.2f", item.margin),
            ratio: String(format: "%.2f", item.ratio),
            updatedAtText: String(item.updatedAt),
            allergy: item.allergy,
            summary: item.summary,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalBedBoardDraftViews(_ items: [GlobalBedBoardDraft]) -> [GlobalBedBoardDraftView] {
        var views: [GlobalBedBoardDraftView] = []
        for item in items {
            views.append(toGlobalBedBoardDraftView(item))
        }
        return views
    }

    static func sumGlobalBedBoardDraftView(_ view: GlobalBedBoardDraftView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMargin + parsedRatio + Double(parsedUpdatedAt)
    }
}
