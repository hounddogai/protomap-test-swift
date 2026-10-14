import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped dispense checkpoint.
    final class CappedDispenseCheckpointView {
        var code: String
        var title: String
        var payer: String
        var unit: String
        var archived: String
        var procedureCode: String
        var contactEmailText: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, payer: String, unit: String, archived: String, procedureCode: String, contactEmailText: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payer = payer
            self.unit = unit
            self.archived = archived
            self.procedureCode = procedureCode
            self.contactEmailText = contactEmailText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDispenseCheckpointView(_ item: CappedDispenseCheckpoint) -> CappedDispenseCheckpointView {
        return CappedDispenseCheckpointView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            payer: item.payer,
            unit: item.unit,
            archived: "\(item.archived)",
            procedureCode: item.procedureCode,
            contactEmailText: item.contactEmail,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDispenseCheckpointViews(_ items: [CappedDispenseCheckpoint]) -> [CappedDispenseCheckpointView] {
        var views: [CappedDispenseCheckpointView] = []
        for item in items {
            views.append(toCappedDispenseCheckpointView(item))
        }
        return views
    }

    static func sumCappedDispenseCheckpointView(_ view: CappedDispenseCheckpointView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
