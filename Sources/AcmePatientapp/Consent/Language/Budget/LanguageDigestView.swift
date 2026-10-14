import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language digest.
    final class LanguageDigestView {
        var code: String
        var name: String
        var checksum: String
        var revision: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, checksum: String, revision: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.revision = revision
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageDigestView(_ item: LanguageDigest) -> LanguageDigestView {
        return LanguageDigestView(
            code: item.code,
            name: item.name,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            revision: String(item.revision),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageDigestViews(_ items: [LanguageDigest]) -> [LanguageDigestView] {
        var views: [LanguageDigestView] = []
        for item in items {
            views.append(toLanguageDigestView(item))
        }
        return views
    }

    static func sumLanguageDigestView(_ view: LanguageDigestView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedRevision) + parsedBudget
    }
}
