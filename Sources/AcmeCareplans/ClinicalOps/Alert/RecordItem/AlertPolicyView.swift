import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert policy.
    final class AlertPolicyView {
        var code: String
        var nameText: String
        var expiresAtText: String
        var procedureCode: String
        var rateText: String
        var statusLabel: String

        init(code: String, nameText: String, expiresAtText: String, procedureCode: String, rateText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.expiresAtText = expiresAtText
            self.procedureCode = procedureCode
            self.rateText = rateText
            self.statusLabel = statusLabel
        }
    }

    static func toAlertPolicyView(_ item: AlertPolicy) -> AlertPolicyView {
        return AlertPolicyView(
            code: item.code,
            nameText: item.name,
            expiresAtText: String(item.expiresAt),
            procedureCode: item.procedureCode,
            rateText: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertPolicyViews(_ items: [AlertPolicy]) -> [AlertPolicyView] {
        var views: [AlertPolicyView] = []
        for item in items {
            views.append(toAlertPolicyView(item))
        }
        return views
    }

    static func sumAlertPolicyView(_ view: AlertPolicyView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedExpiresAt) + parsedRate
    }
}
