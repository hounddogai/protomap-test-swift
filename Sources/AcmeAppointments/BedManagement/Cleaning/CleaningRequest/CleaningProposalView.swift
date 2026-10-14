import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning proposal.
    final class CleaningProposalView {
        var code: String
        var labelText: String
        var source: String
        var threshold: String
        var limit: String
        var patientRef: String
        var windowDays: String
        var channelText: String
        var margin: String
        var statusLabel: String

        init(code: String, labelText: String, source: String, threshold: String, limit: String, patientRef: String, windowDays: String, channelText: String, margin: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.source = source
            self.threshold = threshold
            self.limit = limit
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.channelText = channelText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningProposalView(_ item: CleaningProposal) -> CleaningProposalView {
        return CleaningProposalView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            source: item.source,
            threshold: String(format: "%.2f", item.threshold),
            limit: String(item.limit),
            patientRef: item.patientRef,
            windowDays: String(item.windowDays),
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningProposalViews(_ items: [CleaningProposal]) -> [CleaningProposalView] {
        var views: [CleaningProposalView] = []
        for item in items {
            views.append(toCleaningProposalView(item))
        }
        return views
    }

    static func sumCleaningProposalView(_ view: CleaningProposalView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedThreshold + Double(parsedLimit) + Double(parsedWindowDays)
    }
}
