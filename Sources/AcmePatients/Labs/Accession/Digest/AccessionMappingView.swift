import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession mapping.
    final class AccessionMappingView {
        var code: String
        var titleText: String
        var updatedAtText: String
        var externalRef: String
        var rate: String
        var payer: String
        var thresholdText: String
        var attempts: String
        var acuityText: String
        var specialty: String
        var refills: String
        var statusLabel: String

        init(code: String, titleText: String, updatedAtText: String, externalRef: String, rate: String, payer: String, thresholdText: String, attempts: String, acuityText: String, specialty: String, refills: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.updatedAtText = updatedAtText
            self.externalRef = externalRef
            self.rate = rate
            self.payer = payer
            self.thresholdText = thresholdText
            self.attempts = attempts
            self.acuityText = acuityText
            self.specialty = specialty
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionMappingView(_ item: AccessionMapping) -> AccessionMappingView {
        return AccessionMappingView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            updatedAtText: String(item.updatedAt),
            externalRef: item.externalRef,
            rate: String(format: "%.2f", item.rate),
            payer: item.payer,
            thresholdText: String(format: "%.2f", item.threshold),
            attempts: String(item.attempts),
            acuityText: String(item.acuity),
            specialty: item.specialty,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionMappingViews(_ items: [AccessionMapping]) -> [AccessionMappingView] {
        var views: [AccessionMappingView] = []
        for item in items {
            views.append(toAccessionMappingView(item))
        }
        return views
    }

    static func sumAccessionMappingView(_ view: AccessionMappingView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedUpdatedAt) + parsedRate + parsedThreshold
    }
}
