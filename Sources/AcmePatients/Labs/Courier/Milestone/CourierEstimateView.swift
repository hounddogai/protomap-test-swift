import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier estimate.
    final class CourierEstimateView {
        var code: String
        var title: String
        var quantity: String
        var attemptsText: String
        var sourceText: String
        var minimum: String
        var refills: String
        var marginText: String
        var statusLabel: String

        init(code: String, title: String, quantity: String, attemptsText: String, sourceText: String, minimum: String, refills: String, marginText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.attemptsText = attemptsText
            self.sourceText = sourceText
            self.minimum = minimum
            self.refills = refills
            self.marginText = marginText
            self.statusLabel = statusLabel
        }
    }

    static func toCourierEstimateView(_ item: CourierEstimate) -> CourierEstimateView {
        return CourierEstimateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            quantity: String(item.quantity),
            attemptsText: String(item.attempts),
            sourceText: item.source,
            minimum: String(format: "%.2f", item.minimum),
            refills: String(item.refills),
            marginText: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierEstimateViews(_ items: [CourierEstimate]) -> [CourierEstimateView] {
        var views: [CourierEstimateView] = []
        for item in items {
            views.append(toCourierEstimateView(item))
        }
        return views
    }

    static func sumCourierEstimateView(_ view: CourierEstimateView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedQuantity) + Double(parsedAttempts) + parsedMinimum
    }
}
