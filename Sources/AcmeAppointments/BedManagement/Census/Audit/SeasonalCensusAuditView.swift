import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a seasonal census audit.
    final class SeasonalCensusAuditView {
        var code: String
        var label: String
        var margin: String
        var visitMinutesText: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, margin: String, visitMinutesText: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.margin = margin
            self.visitMinutesText = visitMinutesText
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCensusAuditView(_ item: SeasonalCensusAudit) -> SeasonalCensusAuditView {
        return SeasonalCensusAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 80),
            margin: String(format: "%.2f", item.margin),
            visitMinutesText: String(item.visitMinutes),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCensusAuditViews(_ items: [SeasonalCensusAudit]) -> [SeasonalCensusAuditView] {
        var views: [SeasonalCensusAuditView] = []
        for item in items {
            views.append(toSeasonalCensusAuditView(item))
        }
        return views
    }

    static func sumSeasonalCensusAuditView(_ view: SeasonalCensusAuditView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedMargin + Double(parsedVisitMinutes)
    }
}
