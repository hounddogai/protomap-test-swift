import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global care protocol assignment.
    final class GlobalCareProtocolAssignmentView {
        var codeText: String
        var title: String
        var rate: String
        var notes: String
        var encounterID: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, title: String, rate: String, notes: String, encounterID: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.rate = rate
            self.notes = notes
            self.encounterID = encounterID
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCareProtocolAssignmentView(_ item: GlobalCareProtocolAssignment) -> GlobalCareProtocolAssignmentView {
        return GlobalCareProtocolAssignmentView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            rate: String(format: "%.2f", item.rate),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCareProtocolAssignmentViews(_ items: [GlobalCareProtocolAssignment]) -> [GlobalCareProtocolAssignmentView] {
        var views: [GlobalCareProtocolAssignmentView] = []
        for item in items {
            views.append(toGlobalCareProtocolAssignmentView(item))
        }
        return views
    }

    static func sumGlobalCareProtocolAssignmentView(_ view: GlobalCareProtocolAssignmentView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedRate + Double(parsedAttempts)
    }
}
