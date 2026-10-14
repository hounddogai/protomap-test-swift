import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling recall proposal.
    final class RollingRecallProposalView {
        var code: String
        var label: String
        var pinned: String
        var ratioText: String
        var procedureCodeText: String
        var regionText: String
        var localeText: String
        var endsAtText: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, label: String, pinned: String, ratioText: String, procedureCodeText: String, regionText: String, localeText: String, endsAtText: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.ratioText = ratioText
            self.procedureCodeText = procedureCodeText
            self.regionText = regionText
            self.localeText = localeText
            self.endsAtText = endsAtText
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingRecallProposalView(_ item: RollingRecallProposal) -> RollingRecallProposalView {
        return RollingRecallProposalView(
            code: item.code,
            label: item.label,
            pinned: "\(item.pinned)",
            ratioText: String(format: "%.2f", item.ratio),
            procedureCodeText: item.procedureCode,
            regionText: item.region,
            localeText: item.locale,
            endsAtText: String(item.endsAt),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingRecallProposalViews(_ items: [RollingRecallProposal]) -> [RollingRecallProposalView] {
        var views: [RollingRecallProposalView] = []
        for item in items {
            views.append(toRollingRecallProposalView(item))
        }
        return views
    }

    static func sumRollingRecallProposalView(_ view: RollingRecallProposalView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedRatio + Double(parsedEndsAt)
    }
}
