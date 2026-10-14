import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient bed board profile.
    final class LenientBedBoardProfileView {
        var codeText: String
        var nameText: String
        var endsAtText: String
        var createdAt: String
        var attemptsText: String
        var version: String
        var procedureCodeText: String
        var statusLabel: String

        init(codeText: String, nameText: String, endsAtText: String, createdAt: String, attemptsText: String, version: String, procedureCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.endsAtText = endsAtText
            self.createdAt = createdAt
            self.attemptsText = attemptsText
            self.version = version
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientBedBoardProfileView(_ item: LenientBedBoardProfile) -> LenientBedBoardProfileView {
        return LenientBedBoardProfileView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            endsAtText: String(item.endsAt),
            createdAt: String(item.createdAt),
            attemptsText: String(item.attempts),
            version: String(item.version),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientBedBoardProfileViews(_ items: [LenientBedBoardProfile]) -> [LenientBedBoardProfileView] {
        var views: [LenientBedBoardProfileView] = []
        for item in items {
            views.append(toLenientBedBoardProfileView(item))
        }
        return views
    }

    static func sumLenientBedBoardProfileView(_ view: LenientBedBoardProfileView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedCreatedAt) + Double(parsedAttempts)
    }
}
