import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment estimate.
    final class AssessmentEstimateView {
        var code: String
        var nameText: String
        var procedureCodeText: String
        var costText: String
        var channelText: String
        var notes: String
        var statusLabel: String

        init(code: String, nameText: String, procedureCodeText: String, costText: String, channelText: String, notes: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.procedureCodeText = procedureCodeText
            self.costText = costText
            self.channelText = channelText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentEstimateView(_ item: AssessmentEstimate) -> AssessmentEstimateView {
        return AssessmentEstimateView(
            code: item.code,
            nameText: item.name,
            procedureCodeText: item.procedureCode,
            costText: String(format: "%.2f", item.cost),
            channelText: item.channel,
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentEstimateViews(_ items: [AssessmentEstimate]) -> [AssessmentEstimateView] {
        var views: [AssessmentEstimateView] = []
        for item in items {
            views.append(toAssessmentEstimateView(item))
        }
        return views
    }

    static func sumAssessmentEstimateView(_ view: AssessmentEstimateView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
