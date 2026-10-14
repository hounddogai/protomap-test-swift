import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program baseline.
    final class ProgramBaselineView {
        var code: String
        var title: String
        var summaryText: String
        var retries: String
        var notes: String
        var attempts: String
        var approved: String
        var patientRef: String
        var budget: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, summaryText: String, retries: String, notes: String, attempts: String, approved: String, patientRef: String, budget: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.summaryText = summaryText
            self.retries = retries
            self.notes = notes
            self.attempts = attempts
            self.approved = approved
            self.patientRef = patientRef
            self.budget = budget
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toProgramBaselineView(_ item: ProgramBaseline) -> ProgramBaselineView {
        return ProgramBaselineView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            retries: String(item.retries),
            notes: item.notes,
            attempts: String(item.attempts),
            approved: "\(item.approved)",
            patientRef: item.patientRef,
            budget: String(format: "%.2f", item.budget),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramBaselineViews(_ items: [ProgramBaseline]) -> [ProgramBaselineView] {
        var views: [ProgramBaselineView] = []
        for item in items {
            views.append(toProgramBaselineView(item))
        }
        return views
    }

    static func sumProgramBaselineView(_ view: ProgramBaselineView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedRetries) + Double(parsedAttempts) + parsedBudget
    }
}
