import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation preference.
    final class RevocationPreferenceView {
        var code: String
        var title: String
        var visitMinutes: String
        var copay: String
        var approved: String
        var notesText: String
        var statusLabel: String

        init(code: String, title: String, visitMinutes: String, copay: String, approved: String, notesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.approved = approved
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationPreferenceView(_ item: RevocationPreference) -> RevocationPreferenceView {
        return RevocationPreferenceView(
            code: item.code,
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            copay: String(format: "%.2f", item.copay),
            approved: "\(item.approved)",
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationPreferenceViews(_ items: [RevocationPreference]) -> [RevocationPreferenceView] {
        var views: [RevocationPreferenceView] = []
        for item in items {
            views.append(toRevocationPreferenceView(item))
        }
        return views
    }

    static func sumRevocationPreferenceView(_ view: RevocationPreferenceView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCopay
    }
}
