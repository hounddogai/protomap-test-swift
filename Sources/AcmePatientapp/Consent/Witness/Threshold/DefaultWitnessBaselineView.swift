import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default witness baseline.
    final class DefaultWitnessBaselineView {
        var code: String
        var name: String
        var country: String
        var reviewer: String
        var retries: String
        var updatedAt: String
        var maximum: String
        var patientRef: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, country: String, reviewer: String, retries: String, updatedAt: String, maximum: String, patientRef: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.country = country
            self.reviewer = reviewer
            self.retries = retries
            self.updatedAt = updatedAt
            self.maximum = maximum
            self.patientRef = patientRef
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultWitnessBaselineView(_ item: DefaultWitnessBaseline) -> DefaultWitnessBaselineView {
        return DefaultWitnessBaselineView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            country: Kit.Text.truncate(item.country, limit: 120),
            reviewer: item.reviewer,
            retries: String(item.retries),
            updatedAt: String(item.updatedAt),
            maximum: String(format: "%.2f", item.maximum),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultWitnessBaselineViews(_ items: [DefaultWitnessBaseline]) -> [DefaultWitnessBaselineView] {
        var views: [DefaultWitnessBaselineView] = []
        for item in items {
            views.append(toDefaultWitnessBaselineView(item))
        }
        return views
    }

    static func sumDefaultWitnessBaselineView(_ view: DefaultWitnessBaselineView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedRetries) + Double(parsedUpdatedAt) + parsedMaximum
    }
}
