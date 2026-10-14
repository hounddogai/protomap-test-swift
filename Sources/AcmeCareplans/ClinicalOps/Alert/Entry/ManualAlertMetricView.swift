import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a manual alert metric.
    final class ManualAlertMetricView {
        var code: String
        var label: String
        var procedureCode: String
        var specialty: String
        var name: String
        var maximum: String
        var currencyText: String
        var active: String
        var phone: String
        var ward: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, label: String, procedureCode: String, specialty: String, name: String, maximum: String, currencyText: String, active: String, phone: String, ward: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.name = name
            self.maximum = maximum
            self.currencyText = currencyText
            self.active = active
            self.phone = phone
            self.ward = ward
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toManualAlertMetricView(_ item: ManualAlertMetric) -> ManualAlertMetricView {
        return ManualAlertMetricView(
            code: item.code,
            label: item.label,
            procedureCode: item.procedureCode,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            currencyText: item.currency,
            active: "\(item.active)",
            phone: item.phone,
            ward: item.ward,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualAlertMetricViews(_ items: [ManualAlertMetric]) -> [ManualAlertMetricView] {
        var views: [ManualAlertMetricView] = []
        for item in items {
            views.append(toManualAlertMetricView(item))
        }
        return views
    }

    static func sumManualAlertMetricView(_ view: ManualAlertMetricView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
