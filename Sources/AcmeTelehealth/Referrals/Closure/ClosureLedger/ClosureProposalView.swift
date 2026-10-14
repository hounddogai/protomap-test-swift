import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure proposal.
    final class ClosureProposalView {
        var code: String
        var titleText: String
        var durationMinutes: String
        var reviewer: String
        var diagnosisCode: String
        var checksum: String
        var windowDays: String
        var summaryText: String
        var margin: String
        var statusLabel: String

        init(code: String, titleText: String, durationMinutes: String, reviewer: String, diagnosisCode: String, checksum: String, windowDays: String, summaryText: String, margin: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.durationMinutes = durationMinutes
            self.reviewer = reviewer
            self.diagnosisCode = diagnosisCode
            self.checksum = checksum
            self.windowDays = windowDays
            self.summaryText = summaryText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toClosureProposalView(_ item: ClosureProposal) -> ClosureProposalView {
        return ClosureProposalView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            durationMinutes: String(item.durationMinutes),
            reviewer: item.reviewer,
            diagnosisCode: item.diagnosisCode,
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            windowDays: String(item.windowDays),
            summaryText: Kit.Text.truncate(item.summary, limit: 40),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureProposalViews(_ items: [ClosureProposal]) -> [ClosureProposalView] {
        var views: [ClosureProposalView] = []
        for item in items {
            views.append(toClosureProposalView(item))
        }
        return views
    }

    static func sumClosureProposalView(_ view: ClosureProposalView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedWindowDays) + parsedMargin
    }
}
