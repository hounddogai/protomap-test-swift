import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score proposal.
    final class RiskScoreProposalView {
        var code: String
        var name: String
        var rateText: String
        var margin: String
        var clinicianID: String
        var currency: String
        var ratioText: String
        var locale: String
        var statusLabel: String

        init(code: String, name: String, rateText: String, margin: String, clinicianID: String, currency: String, ratioText: String, locale: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.rateText = rateText
            self.margin = margin
            self.clinicianID = clinicianID
            self.currency = currency
            self.ratioText = ratioText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreProposalView(_ item: RiskScoreProposal) -> RiskScoreProposalView {
        return RiskScoreProposalView(
            code: item.code,
            name: item.name,
            rateText: String(format: "%.2f", item.rate),
            margin: String(format: "%.2f", item.margin),
            clinicianID: item.clinicianID,
            currency: item.currency,
            ratioText: String(format: "%.2f", item.ratio),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreProposalViews(_ items: [RiskScoreProposal]) -> [RiskScoreProposalView] {
        var views: [RiskScoreProposalView] = []
        for item in items {
            views.append(toRiskScoreProposalView(item))
        }
        return views
    }

    static func sumRiskScoreProposalView(_ view: RiskScoreProposalView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRate + parsedMargin + parsedRatio
    }
}
