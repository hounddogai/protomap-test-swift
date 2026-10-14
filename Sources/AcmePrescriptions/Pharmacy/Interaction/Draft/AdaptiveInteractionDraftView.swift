import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive interaction draft.
    final class AdaptiveInteractionDraftView {
        var codeText: String
        var label: String
        var visitMinutes: String
        var expiresAt: String
        var sequence: String
        var minimum: String
        var priority: String
        var archived: String
        var statusLabel: String

        init(codeText: String, label: String, visitMinutes: String, expiresAt: String, sequence: String, minimum: String, priority: String, archived: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.visitMinutes = visitMinutes
            self.expiresAt = expiresAt
            self.sequence = sequence
            self.minimum = minimum
            self.priority = priority
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveInteractionDraftView(_ item: AdaptiveInteractionDraft) -> AdaptiveInteractionDraftView {
        return AdaptiveInteractionDraftView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            visitMinutes: String(item.visitMinutes),
            expiresAt: String(item.expiresAt),
            sequence: String(item.sequence),
            minimum: String(format: "%.2f", item.minimum),
            priority: String(item.priority),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveInteractionDraftViews(_ items: [AdaptiveInteractionDraft]) -> [AdaptiveInteractionDraftView] {
        var views: [AdaptiveInteractionDraftView] = []
        for item in items {
            views.append(toAdaptiveInteractionDraftView(item))
        }
        return views
    }

    static func sumAdaptiveInteractionDraftView(_ view: AdaptiveInteractionDraftView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedExpiresAt) + Double(parsedSequence)
    }
}
