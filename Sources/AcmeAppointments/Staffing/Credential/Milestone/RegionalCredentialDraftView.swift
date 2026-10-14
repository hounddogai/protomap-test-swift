import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional credential draft.
    final class RegionalCredentialDraftView {
        var codeText: String
        var nameText: String
        var notes: String
        var discountText: String
        var attempts: String
        var visitMinutes: String
        var capacity: String
        var visibleText: String
        var sourceText: String
        var refills: String
        var statusLabel: String

        init(codeText: String, nameText: String, notes: String, discountText: String, attempts: String, visitMinutes: String, capacity: String, visibleText: String, sourceText: String, refills: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.notes = notes
            self.discountText = discountText
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.visibleText = visibleText
            self.sourceText = sourceText
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCredentialDraftView(_ item: RegionalCredentialDraft) -> RegionalCredentialDraftView {
        return RegionalCredentialDraftView(
            codeText: item.code,
            nameText: item.name,
            notes: Kit.Text.truncate(item.notes, limit: 120),
            discountText: String(format: "%.2f", item.discount),
            attempts: String(item.attempts),
            visitMinutes: String(item.visitMinutes),
            capacity: String(item.capacity),
            visibleText: "\(item.visible)",
            sourceText: Kit.Text.truncate(item.source, limit: 80),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCredentialDraftViews(_ items: [RegionalCredentialDraft]) -> [RegionalCredentialDraftView] {
        var views: [RegionalCredentialDraftView] = []
        for item in items {
            views.append(toRegionalCredentialDraftView(item))
        }
        return views
    }

    static func sumRegionalCredentialDraftView(_ view: RegionalCredentialDraftView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedDiscount + Double(parsedAttempts) + Double(parsedVisitMinutes)
    }
}
