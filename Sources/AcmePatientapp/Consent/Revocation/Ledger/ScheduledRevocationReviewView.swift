import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled revocation review.
    final class ScheduledRevocationReviewView {
        var code: String
        var name: String
        var ceilingText: String
        var labelText: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, name: String, ceilingText: String, labelText: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceilingText = ceilingText
            self.labelText = labelText
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRevocationReviewView(_ item: ScheduledRevocationReview) -> ScheduledRevocationReviewView {
        return ScheduledRevocationReviewView(
            code: item.code,
            name: item.name,
            ceilingText: String(format: "%.2f", item.ceiling),
            labelText: item.label,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRevocationReviewViews(_ items: [ScheduledRevocationReview]) -> [ScheduledRevocationReviewView] {
        var views: [ScheduledRevocationReviewView] = []
        for item in items {
            views.append(toScheduledRevocationReviewView(item))
        }
        return views
    }

    static func sumScheduledRevocationReviewView(_ view: ScheduledRevocationReviewView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
