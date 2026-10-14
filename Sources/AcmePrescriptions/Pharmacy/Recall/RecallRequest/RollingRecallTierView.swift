import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling recall tier.
    final class RollingRecallTierView {
        var code: String
        var name: String
        var ratio: String
        var procedureCode: String
        var notesText: String
        var ownerID: String
        var encounterID: String
        var sourceText: String
        var visibleText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, name: String, ratio: String, procedureCode: String, notesText: String, ownerID: String, encounterID: String, sourceText: String, visibleText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.notesText = notesText
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.sourceText = sourceText
            self.visibleText = visibleText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toRollingRecallTierView(_ item: RollingRecallTier) -> RollingRecallTierView {
        return RollingRecallTierView(
            code: item.code,
            name: item.name,
            ratio: String(format: "%.2f", item.ratio),
            procedureCode: item.procedureCode,
            notesText: item.notes,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            sourceText: Kit.Text.truncate(item.source, limit: 80),
            visibleText: "\(item.visible)",
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingRecallTierViews(_ items: [RollingRecallTier]) -> [RollingRecallTierView] {
        var views: [RollingRecallTierView] = []
        for item in items {
            views.append(toRollingRecallTierView(item))
        }
        return views
    }

    static func sumRollingRecallTierView(_ view: RollingRecallTierView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
