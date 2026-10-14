import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient census plan.
    final class LenientCensusPlanView {
        var codeText: String
        var title: String
        var timezone: String
        var limitText: String
        var diagnosisCodeText: String
        var source: String
        var batchSizeText: String
        var clinicianID: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, title: String, timezone: String, limitText: String, diagnosisCodeText: String, source: String, batchSizeText: String, clinicianID: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.timezone = timezone
            self.limitText = limitText
            self.diagnosisCodeText = diagnosisCodeText
            self.source = source
            self.batchSizeText = batchSizeText
            self.clinicianID = clinicianID
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCensusPlanView(_ item: LenientCensusPlan) -> LenientCensusPlanView {
        return LenientCensusPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            timezone: item.timezone,
            limitText: String(item.limit),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            source: item.source,
            batchSizeText: String(item.batchSize),
            clinicianID: item.clinicianID,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCensusPlanViews(_ items: [LenientCensusPlan]) -> [LenientCensusPlanView] {
        var views: [LenientCensusPlanView] = []
        for item in items {
            views.append(toLenientCensusPlanView(item))
        }
        return views
    }

    static func sumLenientCensusPlanView(_ view: LenientCensusPlanView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedLimit) + Double(parsedBatchSize) + Double(parsedAttempts)
    }
}
