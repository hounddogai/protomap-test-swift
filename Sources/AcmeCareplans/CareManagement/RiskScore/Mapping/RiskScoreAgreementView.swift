import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score agreement.
    final class RiskScoreAgreementView {
        var codeText: String
        var name: String
        var country: String
        var startsAtText: String
        var timezone: String
        var copay: String
        var region: String
        var batchSize: String
        var threshold: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, name: String, country: String, startsAtText: String, timezone: String, copay: String, region: String, batchSize: String, threshold: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.country = country
            self.startsAtText = startsAtText
            self.timezone = timezone
            self.copay = copay
            self.region = region
            self.batchSize = batchSize
            self.threshold = threshold
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreAgreementView(_ item: RiskScoreAgreement) -> RiskScoreAgreementView {
        return RiskScoreAgreementView(
            codeText: item.code,
            name: item.name,
            country: item.country,
            startsAtText: String(item.startsAt),
            timezone: item.timezone,
            copay: String(format: "%.2f", item.copay),
            region: item.region,
            batchSize: String(item.batchSize),
            threshold: String(format: "%.2f", item.threshold),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreAgreementViews(_ items: [RiskScoreAgreement]) -> [RiskScoreAgreementView] {
        var views: [RiskScoreAgreementView] = []
        for item in items {
            views.append(toRiskScoreAgreementView(item))
        }
        return views
    }

    static func sumRiskScoreAgreementView(_ view: RiskScoreAgreementView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedStartsAt) + parsedCopay + Double(parsedBatchSize)
    }
}
