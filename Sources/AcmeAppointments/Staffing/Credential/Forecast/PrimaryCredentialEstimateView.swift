import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary credential estimate.
    final class PrimaryCredentialEstimateView {
        var code: String
        var title: String
        var externalRef: String
        var expiresAt: String
        var sequenceText: String
        var rateText: String
        var unit: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, externalRef: String, expiresAt: String, sequenceText: String, rateText: String, unit: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.sequenceText = sequenceText
            self.rateText = rateText
            self.unit = unit
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCredentialEstimateView(_ item: PrimaryCredentialEstimate) -> PrimaryCredentialEstimateView {
        return PrimaryCredentialEstimateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            externalRef: item.externalRef,
            expiresAt: String(item.expiresAt),
            sequenceText: String(item.sequence),
            rateText: String(format: "%.2f", item.rate),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCredentialEstimateViews(_ items: [PrimaryCredentialEstimate]) -> [PrimaryCredentialEstimateView] {
        var views: [PrimaryCredentialEstimateView] = []
        for item in items {
            views.append(toPrimaryCredentialEstimateView(item))
        }
        return views
    }

    static func sumPrimaryCredentialEstimateView(_ view: PrimaryCredentialEstimateView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedSequence) + parsedRate
    }
}
