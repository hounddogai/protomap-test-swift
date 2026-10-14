import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation metric.
    final class RevocationMetricView {
        var code: String
        var name: String
        var acuityText: String
        var discount: String
        var minimum: String
        var approvedText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, acuityText: String, discount: String, minimum: String, approvedText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.acuityText = acuityText
            self.discount = discount
            self.minimum = minimum
            self.approvedText = approvedText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationMetricView(_ item: RevocationMetric) -> RevocationMetricView {
        return RevocationMetricView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 120),
            acuityText: String(item.acuity),
            discount: String(format: "%.2f", item.discount),
            minimum: String(format: "%.2f", item.minimum),
            approvedText: "\(item.approved)",
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationMetricViews(_ items: [RevocationMetric]) -> [RevocationMetricView] {
        var views: [RevocationMetricView] = []
        for item in items {
            views.append(toRevocationMetricView(item))
        }
        return views
    }

    static func sumRevocationMetricView(_ view: RevocationMetricView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedAcuity) + parsedDiscount + parsedMinimum
    }
}
