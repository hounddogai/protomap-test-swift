import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool proposal.
    final class FloatPoolProposalView {
        var code: String
        var titleText: String
        var windowDaysText: String
        var source: String
        var endsAtText: String
        var label: String
        var channel: String
        var timezone: String
        var graceDays: String
        var attempts: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, titleText: String, windowDaysText: String, source: String, endsAtText: String, label: String, channel: String, timezone: String, graceDays: String, attempts: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.windowDaysText = windowDaysText
            self.source = source
            self.endsAtText = endsAtText
            self.label = label
            self.channel = channel
            self.timezone = timezone
            self.graceDays = graceDays
            self.attempts = attempts
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolProposalView(_ item: FloatPoolProposal) -> FloatPoolProposalView {
        return FloatPoolProposalView(
            code: item.code,
            titleText: item.title,
            windowDaysText: String(item.windowDays),
            source: Kit.Text.truncate(item.source, limit: 40),
            endsAtText: String(item.endsAt),
            label: item.label,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            timezone: item.timezone,
            graceDays: String(item.graceDays),
            attempts: String(item.attempts),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolProposalViews(_ items: [FloatPoolProposal]) -> [FloatPoolProposalView] {
        var views: [FloatPoolProposalView] = []
        for item in items {
            views.append(toFloatPoolProposalView(item))
        }
        return views
    }

    static func sumFloatPoolProposalView(_ view: FloatPoolProposalView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedEndsAt) + Double(parsedGraceDays)
    }
}
