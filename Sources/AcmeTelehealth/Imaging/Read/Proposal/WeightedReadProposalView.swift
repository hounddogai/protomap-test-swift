import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted read proposal.
    final class WeightedReadProposalView {
        var code: String
        var label: String
        var startsAt: String
        var weight: String
        var graceDays: String
        var rate: String
        var specialtyText: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, startsAt: String, weight: String, graceDays: String, rate: String, specialtyText: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.weight = weight
            self.graceDays = graceDays
            self.rate = rate
            self.specialtyText = specialtyText
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedReadProposalView(_ item: WeightedReadProposal) -> WeightedReadProposalView {
        return WeightedReadProposalView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            startsAt: String(item.startsAt),
            weight: String(format: "%.2f", item.weight),
            graceDays: String(item.graceDays),
            rate: String(format: "%.2f", item.rate),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 40),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedReadProposalViews(_ items: [WeightedReadProposal]) -> [WeightedReadProposalView] {
        var views: [WeightedReadProposalView] = []
        for item in items {
            views.append(toWeightedReadProposalView(item))
        }
        return views
    }

    static func sumWeightedReadProposalView(_ view: WeightedReadProposalView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedStartsAt) + parsedWeight + Double(parsedGraceDays)
    }
}
