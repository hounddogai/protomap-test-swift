import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default panel exception.
    final class DefaultPanelExceptionView {
        var code: String
        var label: String
        var expiresAt: String
        var margin: String
        var revisionText: String
        var notesText: String
        var statusLabel: String

        init(code: String, label: String, expiresAt: String, margin: String, revisionText: String, notesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.margin = margin
            self.revisionText = revisionText
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultPanelExceptionView(_ item: DefaultPanelException) -> DefaultPanelExceptionView {
        return DefaultPanelExceptionView(
            code: item.code,
            label: item.label,
            expiresAt: String(item.expiresAt),
            margin: String(format: "%.2f", item.margin),
            revisionText: String(item.revision),
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultPanelExceptionViews(_ items: [DefaultPanelException]) -> [DefaultPanelExceptionView] {
        var views: [DefaultPanelExceptionView] = []
        for item in items {
            views.append(toDefaultPanelExceptionView(item))
        }
        return views
    }

    static func sumDefaultPanelExceptionView(_ view: DefaultPanelExceptionView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedExpiresAt) + parsedMargin + Double(parsedRevision)
    }
}
