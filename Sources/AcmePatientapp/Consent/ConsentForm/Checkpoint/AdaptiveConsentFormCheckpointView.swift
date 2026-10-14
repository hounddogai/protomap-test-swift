import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive consent form checkpoint.
    final class AdaptiveConsentFormCheckpointView {
        var codeText: String
        var title: String
        var version: String
        var sequence: String
        var clinicianIDText: String
        var name: String
        var archivedText: String
        var rateText: String
        var summary: String
        var currencyText: String
        var statusLabel: String

        init(codeText: String, title: String, version: String, sequence: String, clinicianIDText: String, name: String, archivedText: String, rateText: String, summary: String, currencyText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.version = version
            self.sequence = sequence
            self.clinicianIDText = clinicianIDText
            self.name = name
            self.archivedText = archivedText
            self.rateText = rateText
            self.summary = summary
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveConsentFormCheckpointView(_ item: AdaptiveConsentFormCheckpoint) -> AdaptiveConsentFormCheckpointView {
        return AdaptiveConsentFormCheckpointView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            version: String(item.version),
            sequence: String(item.sequence),
            clinicianIDText: item.clinicianID,
            name: Kit.Text.truncate(item.name, limit: 80),
            archivedText: "\(item.archived)",
            rateText: String(format: "%.2f", item.rate),
            summary: item.summary,
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveConsentFormCheckpointViews(_ items: [AdaptiveConsentFormCheckpoint]) -> [AdaptiveConsentFormCheckpointView] {
        var views: [AdaptiveConsentFormCheckpointView] = []
        for item in items {
            views.append(toAdaptiveConsentFormCheckpointView(item))
        }
        return views
    }

    static func sumAdaptiveConsentFormCheckpointView(_ view: AdaptiveConsentFormCheckpointView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedVersion) + Double(parsedSequence) + parsedRate
    }
}
