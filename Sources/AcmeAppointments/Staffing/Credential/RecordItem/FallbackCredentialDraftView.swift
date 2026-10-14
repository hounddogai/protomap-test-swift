import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback credential draft.
    final class FallbackCredentialDraftView {
        var code: String
        var nameText: String
        var expiresAt: String
        var activeText: String
        var diagnosisCode: String
        var archived: String
        var limitText: String
        var timezone: String
        var score: String
        var procedureCode: String
        var category: String
        var statusLabel: String

        init(code: String, nameText: String, expiresAt: String, activeText: String, diagnosisCode: String, archived: String, limitText: String, timezone: String, score: String, procedureCode: String, category: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.expiresAt = expiresAt
            self.activeText = activeText
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.limitText = limitText
            self.timezone = timezone
            self.score = score
            self.procedureCode = procedureCode
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCredentialDraftView(_ item: FallbackCredentialDraft) -> FallbackCredentialDraftView {
        return FallbackCredentialDraftView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            expiresAt: String(item.expiresAt),
            activeText: "\(item.active)",
            diagnosisCode: item.diagnosisCode,
            archived: "\(item.archived)",
            limitText: String(item.limit),
            timezone: item.timezone,
            score: String(format: "%.2f", item.score),
            procedureCode: item.procedureCode,
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCredentialDraftViews(_ items: [FallbackCredentialDraft]) -> [FallbackCredentialDraftView] {
        var views: [FallbackCredentialDraftView] = []
        for item in items {
            views.append(toFallbackCredentialDraftView(item))
        }
        return views
    }

    static func sumFallbackCredentialDraftView(_ view: FallbackCredentialDraftView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedLimit) + parsedScore
    }
}
