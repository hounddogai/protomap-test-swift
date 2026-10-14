import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance metric.
    final class RemittanceMetricView {
        var code: String
        var titleText: String
        var graceDays: String
        var contactEmail: String
        var patientRefText: String
        var minimum: String
        var payer: String
        var copay: String
        var phone: String
        var capacity: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, titleText: String, graceDays: String, contactEmail: String, patientRefText: String, minimum: String, payer: String, copay: String, phone: String, capacity: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.patientRefText = patientRefText
            self.minimum = minimum
            self.payer = payer
            self.copay = copay
            self.phone = phone
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceMetricView(_ item: RemittanceMetric) -> RemittanceMetricView {
        return RemittanceMetricView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            graceDays: String(item.graceDays),
            contactEmail: item.contactEmail,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            payer: item.payer,
            copay: String(format: "%.2f", item.copay),
            phone: item.phone,
            capacity: String(item.capacity),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceMetricViews(_ items: [RemittanceMetric]) -> [RemittanceMetricView] {
        var views: [RemittanceMetricView] = []
        for item in items {
            views.append(toRemittanceMetricView(item))
        }
        return views
    }

    static func sumRemittanceMetricView(_ view: RemittanceMetricView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedGraceDays) + parsedMinimum + parsedCopay
    }
}
