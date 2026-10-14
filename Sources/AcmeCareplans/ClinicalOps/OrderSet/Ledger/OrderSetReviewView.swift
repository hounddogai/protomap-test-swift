import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set review.
    final class OrderSetReviewView {
        var code: String
        var label: String
        var payerText: String
        var patientRefText: String
        var name: String
        var rateText: String
        var copayText: String
        var statusLabel: String

        init(code: String, label: String, payerText: String, patientRefText: String, name: String, rateText: String, copayText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payerText = payerText
            self.patientRefText = patientRefText
            self.name = name
            self.rateText = rateText
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetReviewView(_ item: OrderSetReview) -> OrderSetReviewView {
        return OrderSetReviewView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            payerText: item.payer,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            rateText: String(format: "%.2f", item.rate),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetReviewViews(_ items: [OrderSetReview]) -> [OrderSetReviewView] {
        var views: [OrderSetReviewView] = []
        for item in items {
            views.append(toOrderSetReviewView(item))
        }
        return views
    }

    static func sumOrderSetReviewView(_ view: OrderSetReviewView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedRate + parsedCopay
    }
}
