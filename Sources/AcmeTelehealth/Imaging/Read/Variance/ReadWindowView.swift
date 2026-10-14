import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read window.
    final class ReadWindowView {
        var codeText: String
        var label: String
        var diagnosisCodeText: String
        var approved: String
        var region: String
        var patientRefText: String
        var budget: String
        var statusLabel: String

        init(codeText: String, label: String, diagnosisCodeText: String, approved: String, region: String, patientRefText: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.diagnosisCodeText = diagnosisCodeText
            self.approved = approved
            self.region = region
            self.patientRefText = patientRefText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toReadWindowView(_ item: ReadWindow) -> ReadWindowView {
        return ReadWindowView(
            codeText: item.code,
            label: item.label,
            diagnosisCodeText: item.diagnosisCode,
            approved: "\(item.approved)",
            region: item.region,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadWindowViews(_ items: [ReadWindow]) -> [ReadWindowView] {
        var views: [ReadWindowView] = []
        for item in items {
            views.append(toReadWindowView(item))
        }
        return views
    }

    static func sumReadWindowView(_ view: ReadWindowView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
