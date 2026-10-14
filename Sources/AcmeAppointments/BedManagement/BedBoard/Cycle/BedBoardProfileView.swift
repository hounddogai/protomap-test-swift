import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board profile.
    final class BedBoardProfileView {
        var code: String
        var name: String
        var revisionText: String
        var category: String
        var checksumText: String
        var createdAt: String
        var externalRef: String
        var windowDays: String
        var summary: String
        var payer: String
        var statusLabel: String

        init(code: String, name: String, revisionText: String, category: String, checksumText: String, createdAt: String, externalRef: String, windowDays: String, summary: String, payer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revisionText = revisionText
            self.category = category
            self.checksumText = checksumText
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.summary = summary
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardProfileView(_ item: BedBoardProfile) -> BedBoardProfileView {
        return BedBoardProfileView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            revisionText: String(item.revision),
            category: Kit.Text.truncate(item.category, limit: 64),
            checksumText: item.checksum,
            createdAt: String(item.createdAt),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            windowDays: String(item.windowDays),
            summary: item.summary,
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardProfileViews(_ items: [BedBoardProfile]) -> [BedBoardProfileView] {
        var views: [BedBoardProfileView] = []
        for item in items {
            views.append(toBedBoardProfileView(item))
        }
        return views
    }

    static func sumBedBoardProfileView(_ view: BedBoardProfileView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedRevision) + Double(parsedCreatedAt) + Double(parsedWindowDays)
    }
}
