import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict overtime manifest.
    final class StrictOvertimeManifestView {
        var code: String
        var nameText: String
        var encounterID: String
        var timezone: String
        var procedureCode: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, encounterID: String, timezone: String, procedureCode: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.encounterID = encounterID
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toStrictOvertimeManifestView(_ item: StrictOvertimeManifest) -> StrictOvertimeManifestView {
        return StrictOvertimeManifestView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            encounterID: item.encounterID,
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictOvertimeManifestViews(_ items: [StrictOvertimeManifest]) -> [StrictOvertimeManifestView] {
        var views: [StrictOvertimeManifestView] = []
        for item in items {
            views.append(toStrictOvertimeManifestView(item))
        }
        return views
    }

    static func sumStrictOvertimeManifestView(_ view: StrictOvertimeManifestView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
