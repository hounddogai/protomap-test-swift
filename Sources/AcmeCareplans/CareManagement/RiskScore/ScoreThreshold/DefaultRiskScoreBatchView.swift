import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default risk score batch.
    final class DefaultRiskScoreBatchView {
        var code: String
        var name: String
        var startsAt: String
        var facility: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, startsAt: String, facility: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.facility = facility
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRiskScoreBatchView(_ item: DefaultRiskScoreBatch) -> DefaultRiskScoreBatchView {
        return DefaultRiskScoreBatchView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            startsAt: String(item.startsAt),
            facility: item.facility,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRiskScoreBatchViews(_ items: [DefaultRiskScoreBatch]) -> [DefaultRiskScoreBatchView] {
        var views: [DefaultRiskScoreBatchView] = []
        for item in items {
            views.append(toDefaultRiskScoreBatchView(item))
        }
        return views
    }

    static func sumDefaultRiskScoreBatchView(_ view: DefaultRiskScoreBatchView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
