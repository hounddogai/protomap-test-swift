import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization proposal.
    final class AuthorizationProposalView {
        var code: String
        var label: String
        var threshold: String
        var rate: String
        var floorValueText: String
        var endsAt: String
        var patientRef: String
        var windowDays: String
        var ratio: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, rate: String, floorValueText: String, endsAt: String, patientRef: String, windowDays: String, ratio: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.rate = rate
            self.floorValueText = floorValueText
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.ratio = ratio
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationProposalView(_ item: AuthorizationProposal) -> AuthorizationProposalView {
        return AuthorizationProposalView(
            code: item.code,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            rate: String(format: "%.2f", item.rate),
            floorValueText: String(format: "%.2f", item.floorValue),
            endsAt: String(item.endsAt),
            patientRef: item.patientRef,
            windowDays: String(item.windowDays),
            ratio: String(format: "%.2f", item.ratio),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationProposalViews(_ items: [AuthorizationProposal]) -> [AuthorizationProposalView] {
        var views: [AuthorizationProposalView] = []
        for item in items {
            views.append(toAuthorizationProposalView(item))
        }
        return views
    }

    static func sumAuthorizationProposalView(_ view: AuthorizationProposalView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedThreshold + parsedRate + parsedFloorValue
    }
}
