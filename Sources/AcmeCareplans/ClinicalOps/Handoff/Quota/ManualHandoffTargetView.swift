import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual handoff target.
    final class ManualHandoffTargetView {
        var codeText: String
        var name: String
        var thresholdText: String
        var summaryText: String
        var approved: String
        var weight: String
        var active: String
        var contactEmail: String
        var channelText: String
        var clinicianID: String
        var statusLabel: String

        init(codeText: String, name: String, thresholdText: String, summaryText: String, approved: String, weight: String, active: String, contactEmail: String, channelText: String, clinicianID: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.thresholdText = thresholdText
            self.summaryText = summaryText
            self.approved = approved
            self.weight = weight
            self.active = active
            self.contactEmail = contactEmail
            self.channelText = channelText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toManualHandoffTargetView(_ item: ManualHandoffTarget) -> ManualHandoffTargetView {
        return ManualHandoffTargetView(
            codeText: item.code,
            name: item.name,
            thresholdText: String(format: "%.2f", item.threshold),
            summaryText: item.summary,
            approved: "\(item.approved)",
            weight: String(format: "%.2f", item.weight),
            active: "\(item.active)",
            contactEmail: item.contactEmail,
            channelText: item.channel,
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualHandoffTargetViews(_ items: [ManualHandoffTarget]) -> [ManualHandoffTargetView] {
        var views: [ManualHandoffTargetView] = []
        for item in items {
            views.append(toManualHandoffTargetView(item))
        }
        return views
    }

    static func sumManualHandoffTargetView(_ view: ManualHandoffTargetView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedThreshold + parsedWeight
    }
}
