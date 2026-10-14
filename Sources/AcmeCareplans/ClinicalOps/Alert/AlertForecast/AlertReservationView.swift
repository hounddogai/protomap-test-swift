import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert reservation.
    final class AlertReservationView {
        var codeText: String
        var title: String
        var bed: String
        var segmentText: String
        var channel: String
        var attempts: String
        var sequence: String
        var rate: String
        var statusLabel: String

        init(codeText: String, title: String, bed: String, segmentText: String, channel: String, attempts: String, sequence: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.bed = bed
            self.segmentText = segmentText
            self.channel = channel
            self.attempts = attempts
            self.sequence = sequence
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toAlertReservationView(_ item: AlertReservation) -> AlertReservationView {
        return AlertReservationView(
            codeText: item.code,
            title: item.title,
            bed: item.bed,
            segmentText: item.segment,
            channel: item.channel,
            attempts: String(item.attempts),
            sequence: String(item.sequence),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertReservationViews(_ items: [AlertReservation]) -> [AlertReservationView] {
        var views: [AlertReservationView] = []
        for item in items {
            views.append(toAlertReservationView(item))
        }
        return views
    }

    static func sumAlertReservationView(_ view: AlertReservationView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedAttempts) + Double(parsedSequence) + parsedRate
    }
}
