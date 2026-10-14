import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback handoff plan.
    final class FallbackHandoffPlanView {
        var codeText: String
        var titleText: String
        var rate: String
        var ownerID: String
        var segment: String
        var marginText: String
        var currencyText: String
        var diagnosisCodeText: String
        var patientRef: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, titleText: String, rate: String, ownerID: String, segment: String, marginText: String, currencyText: String, diagnosisCodeText: String, patientRef: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.rate = rate
            self.ownerID = ownerID
            self.segment = segment
            self.marginText = marginText
            self.currencyText = currencyText
            self.diagnosisCodeText = diagnosisCodeText
            self.patientRef = patientRef
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackHandoffPlanView(_ item: FallbackHandoffPlan) -> FallbackHandoffPlanView {
        return FallbackHandoffPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            rate: String(format: "%.2f", item.rate),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            marginText: String(format: "%.2f", item.margin),
            currencyText: Kit.Text.truncate(item.currency, limit: 64),
            diagnosisCodeText: item.diagnosisCode,
            patientRef: item.patientRef,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackHandoffPlanViews(_ items: [FallbackHandoffPlan]) -> [FallbackHandoffPlanView] {
        var views: [FallbackHandoffPlanView] = []
        for item in items {
            views.append(toFallbackHandoffPlanView(item))
        }
        return views
    }

    static func sumFallbackHandoffPlanView(_ view: FallbackHandoffPlanView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedRate + parsedMargin + Double(parsedQuantity)
    }
}
