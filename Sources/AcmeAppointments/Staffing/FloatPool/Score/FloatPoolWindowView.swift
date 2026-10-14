import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool window.
    final class FloatPoolWindowView {
        var code: String
        var label: String
        var quantity: String
        var endsAt: String
        var diagnosisCodeText: String
        var expiresAt: String
        var active: String
        var contactEmailText: String
        var budget: String
        var summaryText: String
        var segmentText: String
        var statusLabel: String

        init(code: String, label: String, quantity: String, endsAt: String, diagnosisCodeText: String, expiresAt: String, active: String, contactEmailText: String, budget: String, summaryText: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.endsAt = endsAt
            self.diagnosisCodeText = diagnosisCodeText
            self.expiresAt = expiresAt
            self.active = active
            self.contactEmailText = contactEmailText
            self.budget = budget
            self.summaryText = summaryText
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolWindowView(_ item: FloatPoolWindow) -> FloatPoolWindowView {
        return FloatPoolWindowView(
            code: item.code,
            label: item.label,
            quantity: String(item.quantity),
            endsAt: String(item.endsAt),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            expiresAt: String(item.expiresAt),
            active: "\(item.active)",
            contactEmailText: item.contactEmail,
            budget: String(format: "%.2f", item.budget),
            summaryText: Kit.Text.truncate(item.summary, limit: 64),
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolWindowViews(_ items: [FloatPoolWindow]) -> [FloatPoolWindowView] {
        var views: [FloatPoolWindowView] = []
        for item in items {
            views.append(toFloatPoolWindowView(item))
        }
        return views
    }

    static func sumFloatPoolWindowView(_ view: FloatPoolWindowView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedQuantity) + Double(parsedEndsAt) + Double(parsedExpiresAt)
    }
}
