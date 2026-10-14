import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a legacy modality review.
    final class LegacyModalityReviewView {
        var code: String
        var label: String
        var minimum: String
        var pinned: String
        var unit: String
        var patientRefText: String
        var category: String
        var retriesText: String
        var priority: String
        var timezoneText: String
        var capacity: String
        var statusLabel: String

        init(code: String, label: String, minimum: String, pinned: String, unit: String, patientRefText: String, category: String, retriesText: String, priority: String, timezoneText: String, capacity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.pinned = pinned
            self.unit = unit
            self.patientRefText = patientRefText
            self.category = category
            self.retriesText = retriesText
            self.priority = priority
            self.timezoneText = timezoneText
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyModalityReviewView(_ item: LegacyModalityReview) -> LegacyModalityReviewView {
        return LegacyModalityReviewView(
            code: item.code,
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            pinned: "\(item.pinned)",
            unit: Kit.Text.truncate(item.unit, limit: 40),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            category: item.category,
            retriesText: String(item.retries),
            priority: String(item.priority),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 64),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyModalityReviewViews(_ items: [LegacyModalityReview]) -> [LegacyModalityReviewView] {
        var views: [LegacyModalityReviewView] = []
        for item in items {
            views.append(toLegacyModalityReviewView(item))
        }
        return views
    }

    static func sumLegacyModalityReviewView(_ view: LegacyModalityReviewView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedMinimum + Double(parsedRetries) + Double(parsedPriority)
    }
}
