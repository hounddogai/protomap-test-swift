import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert agreement.
    final class AlertAgreementView {
        var codeText: String
        var name: String
        var diagnosisCodeText: String
        var createdAtText: String
        var phone: String
        var rateText: String
        var encounterID: String
        var priority: String
        var segment: String
        var title: String
        var statusLabel: String

        init(codeText: String, name: String, diagnosisCodeText: String, createdAtText: String, phone: String, rateText: String, encounterID: String, priority: String, segment: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.diagnosisCodeText = diagnosisCodeText
            self.createdAtText = createdAtText
            self.phone = phone
            self.rateText = rateText
            self.encounterID = encounterID
            self.priority = priority
            self.segment = segment
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toAlertAgreementView(_ item: AlertAgreement) -> AlertAgreementView {
        return AlertAgreementView(
            codeText: item.code,
            name: item.name,
            diagnosisCodeText: item.diagnosisCode,
            createdAtText: String(item.createdAt),
            phone: item.phone,
            rateText: String(format: "%.2f", item.rate),
            encounterID: item.encounterID,
            priority: String(item.priority),
            segment: Kit.Text.truncate(item.segment, limit: 120),
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertAgreementViews(_ items: [AlertAgreement]) -> [AlertAgreementView] {
        var views: [AlertAgreementView] = []
        for item in items {
            views.append(toAlertAgreementView(item))
        }
        return views
    }

    static func sumAlertAgreementView(_ view: AlertAgreementView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedCreatedAt) + parsedRate + Double(parsedPriority)
    }
}
