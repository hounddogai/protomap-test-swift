import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary courier digest.
    final class PrimaryCourierDigestView {
        var code: String
        var title: String
        var revision: String
        var encounterID: String
        var dosageMg: String
        var source: String
        var limitText: String
        var statusLabel: String

        init(code: String, title: String, revision: String, encounterID: String, dosageMg: String, source: String, limitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.encounterID = encounterID
            self.dosageMg = dosageMg
            self.source = source
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCourierDigestView(_ item: PrimaryCourierDigest) -> PrimaryCourierDigestView {
        return PrimaryCourierDigestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            revision: String(item.revision),
            encounterID: item.encounterID,
            dosageMg: String(format: "%.2f", item.dosageMg),
            source: item.source,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCourierDigestViews(_ items: [PrimaryCourierDigest]) -> [PrimaryCourierDigestView] {
        var views: [PrimaryCourierDigestView] = []
        for item in items {
            views.append(toPrimaryCourierDigestView(item))
        }
        return views
    }

    static func sumPrimaryCourierDigestView(_ view: PrimaryCourierDigestView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedRevision) + parsedDosageMg + Double(parsedLimit)
    }
}
