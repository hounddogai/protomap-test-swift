import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession policy.
    final class AccessionPolicyView {
        var codeText: String
        var title: String
        var durationMinutesText: String
        var minimum: String
        var expiresAt: String
        var bed: String
        var active: String
        var sequenceText: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutesText: String, minimum: String, expiresAt: String, bed: String, active: String, sequenceText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutesText = durationMinutesText
            self.minimum = minimum
            self.expiresAt = expiresAt
            self.bed = bed
            self.active = active
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionPolicyView(_ item: AccessionPolicy) -> AccessionPolicyView {
        return AccessionPolicyView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            durationMinutesText: String(item.durationMinutes),
            minimum: String(format: "%.2f", item.minimum),
            expiresAt: String(item.expiresAt),
            bed: item.bed,
            active: "\(item.active)",
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionPolicyViews(_ items: [AccessionPolicy]) -> [AccessionPolicyView] {
        var views: [AccessionPolicyView] = []
        for item in items {
            views.append(toAccessionPolicyView(item))
        }
        return views
    }

    static func sumAccessionPolicyView(_ view: AccessionPolicyView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedDurationMinutes) + parsedMinimum + Double(parsedExpiresAt)
    }
}
