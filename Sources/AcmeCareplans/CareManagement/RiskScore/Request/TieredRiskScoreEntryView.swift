import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered risk score entry.
    final class TieredRiskScoreEntryView {
        var code: String
        var name: String
        var rate: String
        var countryText: String
        var thresholdText: String
        var channel: String
        var revision: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, name: String, rate: String, countryText: String, thresholdText: String, channel: String, revision: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.rate = rate
            self.countryText = countryText
            self.thresholdText = thresholdText
            self.channel = channel
            self.revision = revision
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRiskScoreEntryView(_ item: TieredRiskScoreEntry) -> TieredRiskScoreEntryView {
        return TieredRiskScoreEntryView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            rate: String(format: "%.2f", item.rate),
            countryText: item.country,
            thresholdText: String(format: "%.2f", item.threshold),
            channel: item.channel,
            revision: String(item.revision),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRiskScoreEntryViews(_ items: [TieredRiskScoreEntry]) -> [TieredRiskScoreEntryView] {
        var views: [TieredRiskScoreEntryView] = []
        for item in items {
            views.append(toTieredRiskScoreEntryView(item))
        }
        return views
    }

    static func sumTieredRiskScoreEntryView(_ view: TieredRiskScoreEntryView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedRate + parsedThreshold + Double(parsedRevision)
    }
}
