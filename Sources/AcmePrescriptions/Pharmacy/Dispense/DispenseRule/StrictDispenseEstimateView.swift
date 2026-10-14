import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict dispense estimate.
    final class StrictDispenseEstimateView {
        var code: String
        var name: String
        var expiresAtText: String
        var graceDays: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, expiresAtText: String, graceDays: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAtText = expiresAtText
            self.graceDays = graceDays
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toStrictDispenseEstimateView(_ item: StrictDispenseEstimate) -> StrictDispenseEstimateView {
        return StrictDispenseEstimateView(
            code: item.code,
            name: item.name,
            expiresAtText: String(item.expiresAt),
            graceDays: String(item.graceDays),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictDispenseEstimateViews(_ items: [StrictDispenseEstimate]) -> [StrictDispenseEstimateView] {
        var views: [StrictDispenseEstimateView] = []
        for item in items {
            views.append(toStrictDispenseEstimateView(item))
        }
        return views
    }

    static func sumStrictDispenseEstimateView(_ view: StrictDispenseEstimateView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedGraceDays) + Double(parsedCreatedAt)
    }
}
