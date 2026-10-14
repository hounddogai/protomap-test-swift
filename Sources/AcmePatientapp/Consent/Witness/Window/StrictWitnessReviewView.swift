import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict witness review.
    final class StrictWitnessReviewView {
        var code: String
        var label: String
        var capacity: String
        var maximum: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, maximum: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.maximum = maximum
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toStrictWitnessReviewView(_ item: StrictWitnessReview) -> StrictWitnessReviewView {
        return StrictWitnessReviewView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            capacity: String(item.capacity),
            maximum: String(format: "%.2f", item.maximum),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictWitnessReviewViews(_ items: [StrictWitnessReview]) -> [StrictWitnessReviewView] {
        var views: [StrictWitnessReviewView] = []
        for item in items {
            views.append(toStrictWitnessReviewView(item))
        }
        return views
    }

    static func sumStrictWitnessReviewView(_ view: StrictWitnessReviewView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedCapacity) + parsedMaximum
    }
}
