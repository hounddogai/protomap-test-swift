import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive risk score threshold.
    final class AdaptiveRiskScoreThresholdView {
        var codeText: String
        var title: String
        var durationMinutes: String
        var wardText: String
        var revision: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutes: String, wardText: String, revision: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutes = durationMinutes
            self.wardText = wardText
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRiskScoreThresholdView(_ item: AdaptiveRiskScoreThreshold) -> AdaptiveRiskScoreThresholdView {
        return AdaptiveRiskScoreThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            durationMinutes: String(item.durationMinutes),
            wardText: Kit.Text.truncate(item.ward, limit: 80),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRiskScoreThresholdViews(_ items: [AdaptiveRiskScoreThreshold]) -> [AdaptiveRiskScoreThresholdView] {
        var views: [AdaptiveRiskScoreThresholdView] = []
        for item in items {
            views.append(toAdaptiveRiskScoreThresholdView(item))
        }
        return views
    }

    static func sumAdaptiveRiskScoreThresholdView(_ view: AdaptiveRiskScoreThresholdView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedRevision)
    }
}
