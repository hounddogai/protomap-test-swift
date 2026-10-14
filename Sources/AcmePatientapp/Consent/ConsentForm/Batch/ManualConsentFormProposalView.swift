import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual consent form proposal.
    final class ManualConsentFormProposalView {
        var code: String
        var nameText: String
        var country: String
        var activeText: String
        var version: String
        var externalRef: String
        var segment: String
        var copay: String
        var statusLabel: String

        init(code: String, nameText: String, country: String, activeText: String, version: String, externalRef: String, segment: String, copay: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.country = country
            self.activeText = activeText
            self.version = version
            self.externalRef = externalRef
            self.segment = segment
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toManualConsentFormProposalView(_ item: ManualConsentFormProposal) -> ManualConsentFormProposalView {
        return ManualConsentFormProposalView(
            code: item.code,
            nameText: item.name,
            country: item.country,
            activeText: "\(item.active)",
            version: String(item.version),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            segment: item.segment,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualConsentFormProposalViews(_ items: [ManualConsentFormProposal]) -> [ManualConsentFormProposalView] {
        var views: [ManualConsentFormProposalView] = []
        for item in items {
            views.append(toManualConsentFormProposalView(item))
        }
        return views
    }

    static func sumManualConsentFormProposalView(_ view: ManualConsentFormProposalView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVersion) + parsedCopay
    }
}
