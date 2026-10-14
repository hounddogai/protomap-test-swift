import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled proxy proposal.
    final class ScheduledProxyProposalView {
        var code: String
        var label: String
        var rate: String
        var versionText: String
        var patientRef: String
        var titleText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, label: String, rate: String, versionText: String, patientRef: String, titleText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rate = rate
            self.versionText = versionText
            self.patientRef = patientRef
            self.titleText = titleText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledProxyProposalView(_ item: ScheduledProxyProposal) -> ScheduledProxyProposalView {
        return ScheduledProxyProposalView(
            code: item.code,
            label: item.label,
            rate: String(format: "%.2f", item.rate),
            versionText: String(item.version),
            patientRef: item.patientRef,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledProxyProposalViews(_ items: [ScheduledProxyProposal]) -> [ScheduledProxyProposalView] {
        var views: [ScheduledProxyProposalView] = []
        for item in items {
            views.append(toScheduledProxyProposalView(item))
        }
        return views
    }

    static func sumScheduledProxyProposalView(_ view: ScheduledProxyProposalView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedRate + Double(parsedVersion)
    }
}
