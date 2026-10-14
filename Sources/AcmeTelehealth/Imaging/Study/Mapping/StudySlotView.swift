import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study slot.
    final class StudySlotView {
        var code: String
        var titleText: String
        var batchSizeText: String
        var payer: String
        var bed: String
        var sequenceText: String
        var updatedAt: String
        var ratio: String
        var statusLabel: String

        init(code: String, titleText: String, batchSizeText: String, payer: String, bed: String, sequenceText: String, updatedAt: String, ratio: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.batchSizeText = batchSizeText
            self.payer = payer
            self.bed = bed
            self.sequenceText = sequenceText
            self.updatedAt = updatedAt
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toStudySlotView(_ item: StudySlot) -> StudySlotView {
        return StudySlotView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            batchSizeText: String(item.batchSize),
            payer: item.payer,
            bed: item.bed,
            sequenceText: String(item.sequence),
            updatedAt: String(item.updatedAt),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudySlotViews(_ items: [StudySlot]) -> [StudySlotView] {
        var views: [StudySlotView] = []
        for item in items {
            views.append(toStudySlotView(item))
        }
        return views
    }

    static func sumStudySlotView(_ view: StudySlotView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedSequence) + Double(parsedUpdatedAt)
    }
}
