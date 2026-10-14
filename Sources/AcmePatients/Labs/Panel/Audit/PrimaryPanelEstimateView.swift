import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary panel estimate.
    final class PrimaryPanelEstimateView {
        var code: String
        var name: String
        var unit: String
        var createdAt: String
        var endsAt: String
        var archived: String
        var retries: String
        var statusLabel: String

        init(code: String, name: String, unit: String, createdAt: String, endsAt: String, archived: String, retries: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unit = unit
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.archived = archived
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryPanelEstimateView(_ item: PrimaryPanelEstimate) -> PrimaryPanelEstimateView {
        return PrimaryPanelEstimateView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            unit: item.unit,
            createdAt: String(item.createdAt),
            endsAt: String(item.endsAt),
            archived: "\(item.archived)",
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryPanelEstimateViews(_ items: [PrimaryPanelEstimate]) -> [PrimaryPanelEstimateView] {
        var views: [PrimaryPanelEstimateView] = []
        for item in items {
            views.append(toPrimaryPanelEstimateView(item))
        }
        return views
    }

    static func sumPrimaryPanelEstimateView(_ view: PrimaryPanelEstimateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedEndsAt) + Double(parsedRetries)
    }
}
