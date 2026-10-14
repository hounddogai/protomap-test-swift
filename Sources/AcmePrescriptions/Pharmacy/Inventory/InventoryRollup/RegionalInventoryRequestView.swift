import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional inventory request.
    final class RegionalInventoryRequestView {
        var code: String
        var title: String
        var segment: String
        var budget: String
        var specialty: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, title: String, segment: String, budget: String, specialty: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segment = segment
            self.budget = budget
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalInventoryRequestView(_ item: RegionalInventoryRequest) -> RegionalInventoryRequestView {
        return RegionalInventoryRequestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            budget: String(format: "%.2f", item.budget),
            specialty: item.specialty,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalInventoryRequestViews(_ items: [RegionalInventoryRequest]) -> [RegionalInventoryRequestView] {
        var views: [RegionalInventoryRequestView] = []
        for item in items {
            views.append(toRegionalInventoryRequestView(item))
        }
        return views
    }

    static func sumRegionalInventoryRequestView(_ view: RegionalInventoryRequestView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedBudget + Double(parsedExpiresAt)
    }
}
