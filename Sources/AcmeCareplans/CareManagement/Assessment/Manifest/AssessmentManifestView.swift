import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment manifest.
    final class AssessmentManifestView {
        var code: String
        var title: String
        var version: String
        var amount: String
        var margin: String
        var channel: String
        var updatedAt: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, version: String, amount: String, margin: String, channel: String, updatedAt: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.version = version
            self.amount = amount
            self.margin = margin
            self.channel = channel
            self.updatedAt = updatedAt
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentManifestView(_ item: AssessmentManifest) -> AssessmentManifestView {
        return AssessmentManifestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            version: String(item.version),
            amount: String(format: "%.2f", item.amount),
            margin: String(format: "%.2f", item.margin),
            channel: item.channel,
            updatedAt: String(item.updatedAt),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentManifestViews(_ items: [AssessmentManifest]) -> [AssessmentManifestView] {
        var views: [AssessmentManifestView] = []
        for item in items {
            views.append(toAssessmentManifestView(item))
        }
        return views
    }

    static func sumAssessmentManifestView(_ view: AssessmentManifestView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedVersion) + parsedAmount + parsedMargin
    }
}
