import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment digest.
    final class AssessmentDigestView {
        var code: String
        var label: String
        var countryText: String
        var source: String
        var retriesText: String
        var statusLabel: String

        init(code: String, label: String, countryText: String, source: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.countryText = countryText
            self.source = source
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentDigestView(_ item: AssessmentDigest) -> AssessmentDigestView {
        return AssessmentDigestView(
            code: item.code,
            label: item.label,
            countryText: Kit.Text.truncate(item.country, limit: 40),
            source: Kit.Text.truncate(item.source, limit: 120),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentDigestViews(_ items: [AssessmentDigest]) -> [AssessmentDigestView] {
        var views: [AssessmentDigestView] = []
        for item in items {
            views.append(toAssessmentDigestView(item))
        }
        return views
    }

    static func sumAssessmentDigestView(_ view: AssessmentDigestView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
