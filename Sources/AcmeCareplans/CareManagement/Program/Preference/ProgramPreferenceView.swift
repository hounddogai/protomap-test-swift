import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program preference.
    final class ProgramPreferenceView {
        var codeText: String
        var title: String
        var summaryText: String
        var threshold: String
        var dosageMg: String
        var reviewer: String
        var durationMinutesText: String
        var statusLabel: String

        init(codeText: String, title: String, summaryText: String, threshold: String, dosageMg: String, reviewer: String, durationMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.summaryText = summaryText
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.reviewer = reviewer
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toProgramPreferenceView(_ item: ProgramPreference) -> ProgramPreferenceView {
        return ProgramPreferenceView(
            codeText: item.code,
            title: item.title,
            summaryText: item.summary,
            threshold: String(format: "%.2f", item.threshold),
            dosageMg: String(format: "%.2f", item.dosageMg),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramPreferenceViews(_ items: [ProgramPreference]) -> [ProgramPreferenceView] {
        var views: [ProgramPreferenceView] = []
        for item in items {
            views.append(toProgramPreferenceView(item))
        }
        return views
    }

    static func sumProgramPreferenceView(_ view: ProgramPreferenceView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedThreshold + parsedDosageMg + Double(parsedDurationMinutes)
    }
}
