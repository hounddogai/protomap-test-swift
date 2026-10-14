import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality batch.
    final class ModalityBatchView {
        var codeText: String
        var title: String
        var score: String
        var facility: String
        var summary: String
        var nameText: String
        var label: String
        var endsAtText: String
        var refills: String
        var updatedAtText: String
        var statusLabel: String

        init(codeText: String, title: String, score: String, facility: String, summary: String, nameText: String, label: String, endsAtText: String, refills: String, updatedAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.score = score
            self.facility = facility
            self.summary = summary
            self.nameText = nameText
            self.label = label
            self.endsAtText = endsAtText
            self.refills = refills
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toModalityBatchView(_ item: ModalityBatch) -> ModalityBatchView {
        return ModalityBatchView(
            codeText: item.code,
            title: item.title,
            score: String(format: "%.2f", item.score),
            facility: Kit.Text.truncate(item.facility, limit: 80),
            summary: item.summary,
            nameText: item.name,
            label: Kit.Text.truncate(item.label, limit: 40),
            endsAtText: String(item.endsAt),
            refills: String(item.refills),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityBatchViews(_ items: [ModalityBatch]) -> [ModalityBatchView] {
        var views: [ModalityBatchView] = []
        for item in items {
            views.append(toModalityBatchView(item))
        }
        return views
    }

    static func sumModalityBatchView(_ view: ModalityBatchView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedScore + Double(parsedEndsAt) + Double(parsedRefills)
    }
}
