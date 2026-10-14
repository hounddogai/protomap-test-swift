import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default task proposal.
    final class DefaultTaskProposalView {
        var code: String
        var label: String
        var wardText: String
        var maximum: String
        var visible: String
        var copay: String
        var durationMinutesText: String
        var score: String
        var thresholdText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, label: String, wardText: String, maximum: String, visible: String, copay: String, durationMinutesText: String, score: String, thresholdText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.wardText = wardText
            self.maximum = maximum
            self.visible = visible
            self.copay = copay
            self.durationMinutesText = durationMinutesText
            self.score = score
            self.thresholdText = thresholdText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultTaskProposalView(_ item: DefaultTaskProposal) -> DefaultTaskProposalView {
        return DefaultTaskProposalView(
            code: item.code,
            label: item.label,
            wardText: item.ward,
            maximum: String(format: "%.2f", item.maximum),
            visible: "\(item.visible)",
            copay: String(format: "%.2f", item.copay),
            durationMinutesText: String(item.durationMinutes),
            score: String(format: "%.2f", item.score),
            thresholdText: String(format: "%.2f", item.threshold),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultTaskProposalViews(_ items: [DefaultTaskProposal]) -> [DefaultTaskProposalView] {
        var views: [DefaultTaskProposalView] = []
        for item in items {
            views.append(toDefaultTaskProposalView(item))
        }
        return views
    }

    static func sumDefaultTaskProposalView(_ view: DefaultTaskProposalView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMaximum + parsedCopay + Double(parsedDurationMinutes)
    }
}
