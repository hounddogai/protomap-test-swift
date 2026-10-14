import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual network milestone.
    final class ManualNetworkMilestoneView {
        var code: String
        var title: String
        var sequence: String
        var minimumText: String
        var endsAt: String
        var diagnosisCodeText: String
        var externalRefText: String
        var reviewer: String
        var contactEmailText: String
        var bed: String
        var statusLabel: String

        init(code: String, title: String, sequence: String, minimumText: String, endsAt: String, diagnosisCodeText: String, externalRefText: String, reviewer: String, contactEmailText: String, bed: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.minimumText = minimumText
            self.endsAt = endsAt
            self.diagnosisCodeText = diagnosisCodeText
            self.externalRefText = externalRefText
            self.reviewer = reviewer
            self.contactEmailText = contactEmailText
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toManualNetworkMilestoneView(_ item: ManualNetworkMilestone) -> ManualNetworkMilestoneView {
        return ManualNetworkMilestoneView(
            code: item.code,
            title: item.title,
            sequence: String(item.sequence),
            minimumText: String(format: "%.2f", item.minimum),
            endsAt: String(item.endsAt),
            diagnosisCodeText: item.diagnosisCode,
            externalRefText: item.externalRef,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            contactEmailText: item.contactEmail,
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualNetworkMilestoneViews(_ items: [ManualNetworkMilestone]) -> [ManualNetworkMilestoneView] {
        var views: [ManualNetworkMilestoneView] = []
        for item in items {
            views.append(toManualNetworkMilestoneView(item))
        }
        return views
    }

    static func sumManualNetworkMilestoneView(_ view: ManualNetworkMilestoneView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedSequence) + parsedMinimum + Double(parsedEndsAt)
    }
}
