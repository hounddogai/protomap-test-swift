import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result window.
    final class ResultWindowView {
        var code: String
        var title: String
        var amountText: String
        var bed: String
        var pinnedText: String
        var revision: String
        var sourceText: String
        var score: String
        var specialty: String
        var unit: String
        var statusLabel: String

        init(code: String, title: String, amountText: String, bed: String, pinnedText: String, revision: String, sourceText: String, score: String, specialty: String, unit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.amountText = amountText
            self.bed = bed
            self.pinnedText = pinnedText
            self.revision = revision
            self.sourceText = sourceText
            self.score = score
            self.specialty = specialty
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toResultWindowView(_ item: ResultWindow) -> ResultWindowView {
        return ResultWindowView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            amountText: String(format: "%.2f", item.amount),
            bed: item.bed,
            pinnedText: "\(item.pinned)",
            revision: String(item.revision),
            sourceText: Kit.Text.truncate(item.source, limit: 120),
            score: String(format: "%.2f", item.score),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultWindowViews(_ items: [ResultWindow]) -> [ResultWindowView] {
        var views: [ResultWindowView] = []
        for item in items {
            views.append(toResultWindowView(item))
        }
        return views
    }

    static func sumResultWindowView(_ view: ResultWindowView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedAmount + Double(parsedRevision) + parsedScore
    }
}
