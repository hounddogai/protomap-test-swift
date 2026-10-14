import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient assessment score.
    final class LenientAssessmentScoreView {
        var code: String
        var name: String
        var capacity: String
        var cost: String
        var margin: String
        var copay: String
        var clinicianID: String
        var sequence: String
        var ratioText: String
        var score: String
        var discount: String
        var statusLabel: String

        init(code: String, name: String, capacity: String, cost: String, margin: String, copay: String, clinicianID: String, sequence: String, ratioText: String, score: String, discount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.cost = cost
            self.margin = margin
            self.copay = copay
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.ratioText = ratioText
            self.score = score
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toLenientAssessmentScoreView(_ item: LenientAssessmentScore) -> LenientAssessmentScoreView {
        return LenientAssessmentScoreView(
            code: item.code,
            name: item.name,
            capacity: String(item.capacity),
            cost: String(format: "%.2f", item.cost),
            margin: String(format: "%.2f", item.margin),
            copay: String(format: "%.2f", item.copay),
            clinicianID: item.clinicianID,
            sequence: String(item.sequence),
            ratioText: String(format: "%.2f", item.ratio),
            score: String(format: "%.2f", item.score),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientAssessmentScoreViews(_ items: [LenientAssessmentScore]) -> [LenientAssessmentScoreView] {
        var views: [LenientAssessmentScoreView] = []
        for item in items {
            views.append(toLenientAssessmentScoreView(item))
        }
        return views
    }

    static func sumLenientAssessmentScoreView(_ view: LenientAssessmentScoreView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedCapacity) + parsedCost + parsedMargin
    }
}
