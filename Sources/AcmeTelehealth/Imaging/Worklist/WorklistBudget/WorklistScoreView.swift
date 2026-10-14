import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist score.
    final class WorklistScoreView {
        var code: String
        var title: String
        var currency: String
        var visitMinutes: String
        var sequence: String
        var bed: String
        var patientRef: String
        var channel: String
        var specialty: String
        var statusLabel: String

        init(code: String, title: String, currency: String, visitMinutes: String, sequence: String, bed: String, patientRef: String, channel: String, specialty: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.sequence = sequence
            self.bed = bed
            self.patientRef = patientRef
            self.channel = channel
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistScoreView(_ item: WorklistScore) -> WorklistScoreView {
        return WorklistScoreView(
            code: item.code,
            title: item.title,
            currency: Kit.Text.truncate(item.currency, limit: 40),
            visitMinutes: String(item.visitMinutes),
            sequence: String(item.sequence),
            bed: Kit.Text.truncate(item.bed, limit: 40),
            patientRef: item.patientRef,
            channel: Kit.Text.truncate(item.channel, limit: 80),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistScoreViews(_ items: [WorklistScore]) -> [WorklistScoreView] {
        var views: [WorklistScoreView] = []
        for item in items {
            views.append(toWorklistScoreView(item))
        }
        return views
    }

    static func sumWorklistScoreView(_ view: WorklistScoreView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedSequence)
    }
}
