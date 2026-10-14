import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy outreach draft.
    final class LegacyOutreachDraftView {
        var code: String
        var name: String
        var dosageMg: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, name: String, dosageMg: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyOutreachDraftView(_ item: LegacyOutreachDraft) -> LegacyOutreachDraftView {
        return LegacyOutreachDraftView(
            code: item.code,
            name: item.name,
            dosageMg: String(format: "%.2f", item.dosageMg),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyOutreachDraftViews(_ items: [LegacyOutreachDraft]) -> [LegacyOutreachDraftView] {
        var views: [LegacyOutreachDraftView] = []
        for item in items {
            views.append(toLegacyOutreachDraftView(item))
        }
        return views
    }

    static func sumLegacyOutreachDraftView(_ view: LegacyOutreachDraftView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedDosageMg + Double(parsedExpiresAt)
    }
}
