import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling program draft.
    final class RollingProgramDraftView {
        var code: String
        var nameText: String
        var title: String
        var copayText: String
        var updatedAt: String
        var discount: String
        var channel: String
        var locale: String
        var visitMinutes: String
        var procedureCode: String
        var margin: String
        var statusLabel: String

        init(code: String, nameText: String, title: String, copayText: String, updatedAt: String, discount: String, channel: String, locale: String, visitMinutes: String, procedureCode: String, margin: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.title = title
            self.copayText = copayText
            self.updatedAt = updatedAt
            self.discount = discount
            self.channel = channel
            self.locale = locale
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRollingProgramDraftView(_ item: RollingProgramDraft) -> RollingProgramDraftView {
        return RollingProgramDraftView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            title: Kit.Text.truncate(item.title, limit: 64),
            copayText: String(format: "%.2f", item.copay),
            updatedAt: String(item.updatedAt),
            discount: String(format: "%.2f", item.discount),
            channel: item.channel,
            locale: item.locale,
            visitMinutes: String(item.visitMinutes),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingProgramDraftViews(_ items: [RollingProgramDraft]) -> [RollingProgramDraftView] {
        var views: [RollingProgramDraftView] = []
        for item in items {
            views.append(toRollingProgramDraftView(item))
        }
        return views
    }

    static func sumRollingProgramDraftView(_ view: RollingProgramDraftView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCopay + Double(parsedUpdatedAt) + parsedDiscount
    }
}
