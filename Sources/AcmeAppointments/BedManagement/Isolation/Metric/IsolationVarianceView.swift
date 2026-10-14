import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation variance.
    final class IsolationVarianceView {
        var code: String
        var titleText: String
        var ownerIDText: String
        var graceDays: String
        var quantityText: String
        var diagnosisCode: String
        var updatedAt: String
        var startsAt: String
        var statusLabel: String

        init(code: String, titleText: String, ownerIDText: String, graceDays: String, quantityText: String, diagnosisCode: String, updatedAt: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ownerIDText = ownerIDText
            self.graceDays = graceDays
            self.quantityText = quantityText
            self.diagnosisCode = diagnosisCode
            self.updatedAt = updatedAt
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationVarianceView(_ item: IsolationVariance) -> IsolationVarianceView {
        return IsolationVarianceView(
            code: item.code,
            titleText: item.title,
            ownerIDText: item.ownerID,
            graceDays: String(item.graceDays),
            quantityText: String(item.quantity),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            updatedAt: String(item.updatedAt),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationVarianceViews(_ items: [IsolationVariance]) -> [IsolationVarianceView] {
        var views: [IsolationVarianceView] = []
        for item in items {
            views.append(toIsolationVarianceView(item))
        }
        return views
    }

    static func sumIsolationVarianceView(_ view: IsolationVarianceView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedQuantity) + Double(parsedUpdatedAt)
    }
}
