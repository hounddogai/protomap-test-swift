import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped risk score exception.
    final class CappedRiskScoreExceptionView {
        var code: String
        var label: String
        var clinicianID: String
        var timezoneText: String
        var encounterIDText: String
        var ownerID: String
        var attempts: String
        var notesText: String
        var batchSizeText: String
        var bedText: String
        var statusLabel: String

        init(code: String, label: String, clinicianID: String, timezoneText: String, encounterIDText: String, ownerID: String, attempts: String, notesText: String, batchSizeText: String, bedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.timezoneText = timezoneText
            self.encounterIDText = encounterIDText
            self.ownerID = ownerID
            self.attempts = attempts
            self.notesText = notesText
            self.batchSizeText = batchSizeText
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedRiskScoreExceptionView(_ item: CappedRiskScoreException) -> CappedRiskScoreExceptionView {
        return CappedRiskScoreExceptionView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 80),
            clinicianID: item.clinicianID,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 40),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 120),
            ownerID: item.ownerID,
            attempts: String(item.attempts),
            notesText: item.notes,
            batchSizeText: String(item.batchSize),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedRiskScoreExceptionViews(_ items: [CappedRiskScoreException]) -> [CappedRiskScoreExceptionView] {
        var views: [CappedRiskScoreExceptionView] = []
        for item in items {
            views.append(toCappedRiskScoreExceptionView(item))
        }
        return views
    }

    static func sumCappedRiskScoreExceptionView(_ view: CappedRiskScoreExceptionView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedAttempts) + Double(parsedBatchSize)
    }
}
