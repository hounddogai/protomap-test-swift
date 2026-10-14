import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study reservation.
    final class StudyReservationView {
        var code: String
        var nameText: String
        var refillsText: String
        var retriesText: String
        var attemptsText: String
        var patientRef: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, refillsText: String, retriesText: String, attemptsText: String, patientRef: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.refillsText = refillsText
            self.retriesText = retriesText
            self.attemptsText = attemptsText
            self.patientRef = patientRef
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toStudyReservationView(_ item: StudyReservation) -> StudyReservationView {
        return StudyReservationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            refillsText: String(item.refills),
            retriesText: String(item.retries),
            attemptsText: String(item.attempts),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyReservationViews(_ items: [StudyReservation]) -> [StudyReservationView] {
        var views: [StudyReservationView] = []
        for item in items {
            views.append(toStudyReservationView(item))
        }
        return views
    }

    static func sumStudyReservationView(_ view: StudyReservationView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRefills) + Double(parsedRetries) + Double(parsedAttempts)
    }
}
