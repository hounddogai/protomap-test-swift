import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient read assignment.
    final class LenientReadAssignmentView {
        var codeText: String
        var name: String
        var allergy: String
        var graceDays: String
        var notes: String
        var attemptsText: String
        var expiresAtText: String
        var procedureCode: String
        var source: String
        var statusLabel: String

        init(codeText: String, name: String, allergy: String, graceDays: String, notes: String, attemptsText: String, expiresAtText: String, procedureCode: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.allergy = allergy
            self.graceDays = graceDays
            self.notes = notes
            self.attemptsText = attemptsText
            self.expiresAtText = expiresAtText
            self.procedureCode = procedureCode
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toLenientReadAssignmentView(_ item: LenientReadAssignment) -> LenientReadAssignmentView {
        return LenientReadAssignmentView(
            codeText: item.code,
            name: item.name,
            allergy: item.allergy,
            graceDays: String(item.graceDays),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            attemptsText: String(item.attempts),
            expiresAtText: String(item.expiresAt),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientReadAssignmentViews(_ items: [LenientReadAssignment]) -> [LenientReadAssignmentView] {
        var views: [LenientReadAssignmentView] = []
        for item in items {
            views.append(toLenientReadAssignmentView(item))
        }
        return views
    }

    static func sumLenientReadAssignmentView(_ view: LenientReadAssignmentView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedAttempts) + Double(parsedExpiresAt)
    }
}
