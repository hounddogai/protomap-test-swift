import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential variance.
    final class CredentialVarianceView {
        var codeText: String
        var label: String
        var quantity: String
        var bed: String
        var copay: String
        var statusLabel: String

        init(codeText: String, label: String, quantity: String, bed: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.quantity = quantity
            self.bed = bed
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialVarianceView(_ item: CredentialVariance) -> CredentialVarianceView {
        return CredentialVarianceView(
            codeText: item.code,
            label: item.label,
            quantity: String(item.quantity),
            bed: Kit.Text.truncate(item.bed, limit: 40),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialVarianceViews(_ items: [CredentialVariance]) -> [CredentialVarianceView] {
        var views: [CredentialVarianceView] = []
        for item in items {
            views.append(toCredentialVarianceView(item))
        }
        return views
    }

    static func sumCredentialVarianceView(_ view: CredentialVarianceView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedQuantity) + parsedCopay
    }
}
