import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program cycle.
    final class ProgramCycleView {
        var code: String
        var titleText: String
        var ward: String
        var diagnosisCode: String
        var summary: String
        var payer: String
        var score: String
        var statusLabel: String

        init(code: String, titleText: String, ward: String, diagnosisCode: String, summary: String, payer: String, score: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.payer = payer
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toProgramCycleView(_ item: ProgramCycle) -> ProgramCycleView {
        return ProgramCycleView(
            code: item.code,
            titleText: item.title,
            ward: item.ward,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            summary: item.summary,
            payer: item.payer,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramCycleViews(_ items: [ProgramCycle]) -> [ProgramCycleView] {
        var views: [ProgramCycleView] = []
        for item in items {
            views.append(toProgramCycleView(item))
        }
        return views
    }

    static func sumProgramCycleView(_ view: ProgramCycleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
