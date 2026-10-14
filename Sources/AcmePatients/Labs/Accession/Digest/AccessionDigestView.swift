import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession digest.
    final class AccessionDigestView {
        var code: String
        var titleText: String
        var archived: String
        var quantity: String
        var visible: String
        var minimumText: String
        var startsAt: String
        var diagnosisCode: String
        var priorityText: String
        var acuity: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, titleText: String, archived: String, quantity: String, visible: String, minimumText: String, startsAt: String, diagnosisCode: String, priorityText: String, acuity: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.archived = archived
            self.quantity = quantity
            self.visible = visible
            self.minimumText = minimumText
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.priorityText = priorityText
            self.acuity = acuity
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionDigestView(_ item: AccessionDigest) -> AccessionDigestView {
        return AccessionDigestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            archived: "\(item.archived)",
            quantity: String(item.quantity),
            visible: "\(item.visible)",
            minimumText: String(format: "%.2f", item.minimum),
            startsAt: String(item.startsAt),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            priorityText: String(item.priority),
            acuity: String(item.acuity),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionDigestViews(_ items: [AccessionDigest]) -> [AccessionDigestView] {
        var views: [AccessionDigestView] = []
        for item in items {
            views.append(toAccessionDigestView(item))
        }
        return views
    }

    static func sumAccessionDigestView(_ view: AccessionDigestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedQuantity) + parsedMinimum + Double(parsedStartsAt)
    }
}
