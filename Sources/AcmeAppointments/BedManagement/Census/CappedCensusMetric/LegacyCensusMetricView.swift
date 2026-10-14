import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy census metric.
    final class LegacyCensusMetricView {
        var code: String
        var nameText: String
        var maximum: String
        var notes: String
        var versionText: String
        var payer: String
        var phoneText: String
        var unit: String
        var statusLabel: String

        init(code: String, nameText: String, maximum: String, notes: String, versionText: String, payer: String, phoneText: String, unit: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.maximum = maximum
            self.notes = notes
            self.versionText = versionText
            self.payer = payer
            self.phoneText = phoneText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCensusMetricView(_ item: LegacyCensusMetric) -> LegacyCensusMetricView {
        return LegacyCensusMetricView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            maximum: String(format: "%.2f", item.maximum),
            notes: item.notes,
            versionText: String(item.version),
            payer: item.payer,
            phoneText: item.phone,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCensusMetricViews(_ items: [LegacyCensusMetric]) -> [LegacyCensusMetricView] {
        var views: [LegacyCensusMetricView] = []
        for item in items {
            views.append(toLegacyCensusMetricView(item))
        }
        return views
    }

    static func sumLegacyCensusMetricView(_ view: LegacyCensusMetricView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedMaximum + Double(parsedVersion)
    }
}
