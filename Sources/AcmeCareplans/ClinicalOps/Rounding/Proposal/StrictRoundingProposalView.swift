import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict rounding proposal.
    final class StrictRoundingProposalView {
        var codeText: String
        var title: String
        var currencyText: String
        var floorValueText: String
        var createdAt: String
        var localeText: String
        var statusLabel: String

        init(codeText: String, title: String, currencyText: String, floorValueText: String, createdAt: String, localeText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.currencyText = currencyText
            self.floorValueText = floorValueText
            self.createdAt = createdAt
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictRoundingProposalView(_ item: StrictRoundingProposal) -> StrictRoundingProposalView {
        return StrictRoundingProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 64),
            currencyText: item.currency,
            floorValueText: String(format: "%.2f", item.floorValue),
            createdAt: String(item.createdAt),
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictRoundingProposalViews(_ items: [StrictRoundingProposal]) -> [StrictRoundingProposalView] {
        var views: [StrictRoundingProposalView] = []
        for item in items {
            views.append(toStrictRoundingProposalView(item))
        }
        return views
    }

    static func sumStrictRoundingProposalView(_ view: StrictRoundingProposalView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedFloorValue + Double(parsedCreatedAt)
    }
}
