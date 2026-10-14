import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert quota.
    final class AlertQuotaView {
        var code: String
        var name: String
        var revision: String
        var discount: String
        var minimum: String
        var maximumText: String
        var batchSize: String
        var retries: String
        var weight: String
        var statusLabel: String

        init(code: String, name: String, revision: String, discount: String, minimum: String, maximumText: String, batchSize: String, retries: String, weight: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.discount = discount
            self.minimum = minimum
            self.maximumText = maximumText
            self.batchSize = batchSize
            self.retries = retries
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toAlertQuotaView(_ item: AlertQuota) -> AlertQuotaView {
        return AlertQuotaView(
            code: item.code,
            name: item.name,
            revision: String(item.revision),
            discount: String(format: "%.2f", item.discount),
            minimum: String(format: "%.2f", item.minimum),
            maximumText: String(format: "%.2f", item.maximum),
            batchSize: String(item.batchSize),
            retries: String(item.retries),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertQuotaViews(_ items: [AlertQuota]) -> [AlertQuotaView] {
        var views: [AlertQuotaView] = []
        for item in items {
            views.append(toAlertQuotaView(item))
        }
        return views
    }

    static func sumAlertQuotaView(_ view: AlertQuotaView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedRevision) + parsedDiscount + parsedMinimum
    }
}
