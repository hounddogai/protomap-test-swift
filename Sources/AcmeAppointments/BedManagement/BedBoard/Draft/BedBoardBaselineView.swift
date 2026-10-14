import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board baseline.
    final class BedBoardBaselineView {
        var codeText: String
        var labelText: String
        var visitMinutes: String
        var locale: String
        var scoreText: String
        var phone: String
        var notes: String
        var refillsText: String
        var externalRefText: String
        var minimum: String
        var approvedText: String
        var statusLabel: String

        init(codeText: String, labelText: String, visitMinutes: String, locale: String, scoreText: String, phone: String, notes: String, refillsText: String, externalRefText: String, minimum: String, approvedText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.visitMinutes = visitMinutes
            self.locale = locale
            self.scoreText = scoreText
            self.phone = phone
            self.notes = notes
            self.refillsText = refillsText
            self.externalRefText = externalRefText
            self.minimum = minimum
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardBaselineView(_ item: BedBoardBaseline) -> BedBoardBaselineView {
        return BedBoardBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            visitMinutes: String(item.visitMinutes),
            locale: item.locale,
            scoreText: String(format: "%.2f", item.score),
            phone: item.phone,
            notes: item.notes,
            refillsText: String(item.refills),
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardBaselineViews(_ items: [BedBoardBaseline]) -> [BedBoardBaselineView] {
        var views: [BedBoardBaselineView] = []
        for item in items {
            views.append(toBedBoardBaselineView(item))
        }
        return views
    }

    static func sumBedBoardBaselineView(_ view: BedBoardBaselineView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore + Double(parsedRefills)
    }
}
