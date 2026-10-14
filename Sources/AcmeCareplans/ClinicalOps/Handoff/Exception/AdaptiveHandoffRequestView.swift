import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive handoff request.
    final class AdaptiveHandoffRequestView {
        var code: String
        var label: String
        var budget: String
        var dosageMg: String
        var summary: String
        var pinned: String
        var channel: String
        var statusLabel: String

        init(code: String, label: String, budget: String, dosageMg: String, summary: String, pinned: String, channel: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.budget = budget
            self.dosageMg = dosageMg
            self.summary = summary
            self.pinned = pinned
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveHandoffRequestView(_ item: AdaptiveHandoffRequest) -> AdaptiveHandoffRequestView {
        return AdaptiveHandoffRequestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            budget: String(format: "%.2f", item.budget),
            dosageMg: String(format: "%.2f", item.dosageMg),
            summary: item.summary,
            pinned: "\(item.pinned)",
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveHandoffRequestViews(_ items: [AdaptiveHandoffRequest]) -> [AdaptiveHandoffRequestView] {
        var views: [AdaptiveHandoffRequestView] = []
        for item in items {
            views.append(toAdaptiveHandoffRequestView(item))
        }
        return views
    }

    static func sumAdaptiveHandoffRequestView(_ view: AdaptiveHandoffRequestView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedBudget + parsedDosageMg
    }
}
