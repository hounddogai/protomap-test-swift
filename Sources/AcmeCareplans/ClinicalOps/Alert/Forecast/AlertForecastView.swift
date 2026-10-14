import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert forecast.
    final class AlertForecastView {
        var codeText: String
        var titleText: String
        var endsAt: String
        var revisionText: String
        var visibleText: String
        var sequenceText: String
        var statusLabel: String

        init(codeText: String, titleText: String, endsAt: String, revisionText: String, visibleText: String, sequenceText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.endsAt = endsAt
            self.revisionText = revisionText
            self.visibleText = visibleText
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toAlertForecastView(_ item: AlertForecast) -> AlertForecastView {
        return AlertForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            endsAt: String(item.endsAt),
            revisionText: String(item.revision),
            visibleText: "\(item.visible)",
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertForecastViews(_ items: [AlertForecast]) -> [AlertForecastView] {
        var views: [AlertForecastView] = []
        for item in items {
            views.append(toAlertForecastView(item))
        }
        return views
    }

    static func sumAlertForecastView(_ view: AlertForecastView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedRevision) + Double(parsedSequence)
    }
}
