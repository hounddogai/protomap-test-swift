import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a pending witness draft.
    final class PendingWitnessDraftView {
        var code: String
        var name: String
        var graceDaysText: String
        var bed: String
        var channel: String
        var diagnosisCode: String
        var retries: String
        var clinicianID: String
        var sequence: String
        var statusLabel: String

        init(code: String, name: String, graceDaysText: String, bed: String, channel: String, diagnosisCode: String, retries: String, clinicianID: String, sequence: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDaysText = graceDaysText
            self.bed = bed
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.retries = retries
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toPendingWitnessDraftView(_ item: PendingWitnessDraft) -> PendingWitnessDraftView {
        return PendingWitnessDraftView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            graceDaysText: String(item.graceDays),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            channel: item.channel,
            diagnosisCode: item.diagnosisCode,
            retries: String(item.retries),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 120),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingWitnessDraftViews(_ items: [PendingWitnessDraft]) -> [PendingWitnessDraftView] {
        var views: [PendingWitnessDraftView] = []
        for item in items {
            views.append(toPendingWitnessDraftView(item))
        }
        return views
    }

    static func sumPendingWitnessDraftView(_ view: PendingWitnessDraftView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRetries) + Double(parsedSequence)
    }
}
