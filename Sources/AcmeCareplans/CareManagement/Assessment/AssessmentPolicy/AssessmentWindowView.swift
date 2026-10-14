import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment window.
    final class AssessmentWindowView {
        var codeText: String
        var label: String
        var graceDays: String
        var margin: String
        var country: String
        var ownerID: String
        var ratioText: String
        var weightText: String
        var createdAtText: String
        var statusLabel: String

        init(codeText: String, label: String, graceDays: String, margin: String, country: String, ownerID: String, ratioText: String, weightText: String, createdAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.graceDays = graceDays
            self.margin = margin
            self.country = country
            self.ownerID = ownerID
            self.ratioText = ratioText
            self.weightText = weightText
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentWindowView(_ item: AssessmentWindow) -> AssessmentWindowView {
        return AssessmentWindowView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            graceDays: String(item.graceDays),
            margin: String(format: "%.2f", item.margin),
            country: item.country,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            ratioText: String(format: "%.2f", item.ratio),
            weightText: String(format: "%.2f", item.weight),
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentWindowViews(_ items: [AssessmentWindow]) -> [AssessmentWindowView] {
        var views: [AssessmentWindowView] = []
        for item in items {
            views.append(toAssessmentWindowView(item))
        }
        return views
    }

    static func sumAssessmentWindowView(_ view: AssessmentWindowView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedGraceDays) + parsedMargin + parsedRatio
    }
}
