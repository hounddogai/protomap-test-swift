import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert review.
    final class AlertReviewView {
        var code: String
        var labelText: String
        var maximum: String
        var thresholdText: String
        var notesText: String
        var ceilingText: String
        var graceDays: String
        var descriptionText: String
        var refills: String
        var statusLabel: String

        init(code: String, labelText: String, maximum: String, thresholdText: String, notesText: String, ceilingText: String, graceDays: String, descriptionText: String, refills: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.maximum = maximum
            self.thresholdText = thresholdText
            self.notesText = notesText
            self.ceilingText = ceilingText
            self.graceDays = graceDays
            self.descriptionText = descriptionText
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toAlertReviewView(_ item: AlertReview) -> AlertReviewView {
        return AlertReviewView(
            code: item.code,
            labelText: item.label,
            maximum: String(format: "%.2f", item.maximum),
            thresholdText: String(format: "%.2f", item.threshold),
            notesText: item.notes,
            ceilingText: String(format: "%.2f", item.ceiling),
            graceDays: String(item.graceDays),
            descriptionText: item.description,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertReviewViews(_ items: [AlertReview]) -> [AlertReviewView] {
        var views: [AlertReviewView] = []
        for item in items {
            views.append(toAlertReviewView(item))
        }
        return views
    }

    static func sumAlertReviewView(_ view: AlertReviewView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedMaximum + parsedThreshold + parsedCeiling
    }
}
