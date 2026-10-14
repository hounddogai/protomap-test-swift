import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional proxy baseline.
    final class RegionalProxyBaselineView {
        var code: String
        var name: String
        var revision: String
        var weight: String
        var source: String
        var limitText: String
        var labelText: String
        var patientRefText: String
        var notesText: String
        var statusLabel: String

        init(code: String, name: String, revision: String, weight: String, source: String, limitText: String, labelText: String, patientRefText: String, notesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.weight = weight
            self.source = source
            self.limitText = limitText
            self.labelText = labelText
            self.patientRefText = patientRefText
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalProxyBaselineView(_ item: RegionalProxyBaseline) -> RegionalProxyBaselineView {
        return RegionalProxyBaselineView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            revision: String(item.revision),
            weight: String(format: "%.2f", item.weight),
            source: item.source,
            limitText: String(item.limit),
            labelText: item.label,
            patientRefText: item.patientRef,
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalProxyBaselineViews(_ items: [RegionalProxyBaseline]) -> [RegionalProxyBaselineView] {
        var views: [RegionalProxyBaselineView] = []
        for item in items {
            views.append(toRegionalProxyBaselineView(item))
        }
        return views
    }

    static func sumRegionalProxyBaselineView(_ view: RegionalProxyBaselineView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedRevision) + parsedWeight + Double(parsedLimit)
    }
}
