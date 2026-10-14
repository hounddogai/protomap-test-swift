import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary order set draft.
    final class PrimaryOrderSetDraftView {
        var codeText: String
        var label: String
        var patientRef: String
        var approved: String
        var name: String
        var margin: String
        var diagnosisCodeText: String
        var channel: String
        var statusLabel: String

        init(codeText: String, label: String, patientRef: String, approved: String, name: String, margin: String, diagnosisCodeText: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.patientRef = patientRef
            self.approved = approved
            self.name = name
            self.margin = margin
            self.diagnosisCodeText = diagnosisCodeText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryOrderSetDraftView(_ item: PrimaryOrderSetDraft) -> PrimaryOrderSetDraftView {
        return PrimaryOrderSetDraftView(
            codeText: item.code,
            label: item.label,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            approved: "\(item.approved)",
            name: item.name,
            margin: String(format: "%.2f", item.margin),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryOrderSetDraftViews(_ items: [PrimaryOrderSetDraft]) -> [PrimaryOrderSetDraftView] {
        var views: [PrimaryOrderSetDraftView] = []
        for item in items {
            views.append(toPrimaryOrderSetDraftView(item))
        }
        return views
    }

    static func sumPrimaryOrderSetDraftView(_ view: PrimaryOrderSetDraftView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
