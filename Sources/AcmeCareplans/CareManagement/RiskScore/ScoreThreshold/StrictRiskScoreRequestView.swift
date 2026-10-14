import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a strict risk score request.
    final class StrictRiskScoreRequestView {
        var codeText: String
        var name: String
        var notes: String
        var patientRefText: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, name: String, notes: String, patientRefText: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.notes = notes
            self.patientRefText = patientRefText
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toStrictRiskScoreRequestView(_ item: StrictRiskScoreRequest) -> StrictRiskScoreRequestView {
        return StrictRiskScoreRequestView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            notes: Kit.Text.truncate(item.notes, limit: 64),
            patientRefText: item.patientRef,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictRiskScoreRequestViews(_ items: [StrictRiskScoreRequest]) -> [StrictRiskScoreRequestView] {
        var views: [StrictRiskScoreRequestView] = []
        for item in items {
            views.append(toStrictRiskScoreRequestView(item))
        }
        return views
    }

    static func sumStrictRiskScoreRequestView(_ view: StrictRiskScoreRequestView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
