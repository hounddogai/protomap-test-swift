import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol review.
    final class CareProtocolReviewView {
        var codeText: String
        var labelText: String
        var unit: String
        var retries: String
        var durationMinutesText: String
        var encounterID: String
        var channel: String
        var ceiling: String
        var diagnosisCodeText: String
        var sourceText: String
        var phone: String
        var statusLabel: String

        init(codeText: String, labelText: String, unit: String, retries: String, durationMinutesText: String, encounterID: String, channel: String, ceiling: String, diagnosisCodeText: String, sourceText: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.unit = unit
            self.retries = retries
            self.durationMinutesText = durationMinutesText
            self.encounterID = encounterID
            self.channel = channel
            self.ceiling = ceiling
            self.diagnosisCodeText = diagnosisCodeText
            self.sourceText = sourceText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolReviewView(_ item: CareProtocolReview) -> CareProtocolReviewView {
        return CareProtocolReviewView(
            codeText: item.code,
            labelText: item.label,
            unit: item.unit,
            retries: String(item.retries),
            durationMinutesText: String(item.durationMinutes),
            encounterID: item.encounterID,
            channel: item.channel,
            ceiling: String(format: "%.2f", item.ceiling),
            diagnosisCodeText: item.diagnosisCode,
            sourceText: item.source,
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolReviewViews(_ items: [CareProtocolReview]) -> [CareProtocolReviewView] {
        var views: [CareProtocolReviewView] = []
        for item in items {
            views.append(toCareProtocolReviewView(item))
        }
        return views
    }

    static func sumCareProtocolReviewView(_ view: CareProtocolReviewView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRetries) + Double(parsedDurationMinutes) + parsedCeiling
    }
}
