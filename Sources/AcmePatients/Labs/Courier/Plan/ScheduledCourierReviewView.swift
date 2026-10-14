import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled courier review.
    final class ScheduledCourierReviewView {
        var codeText: String
        var name: String
        var windowDaysText: String
        var checksum: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, name: String, windowDaysText: String, checksum: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.windowDaysText = windowDaysText
            self.checksum = checksum
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCourierReviewView(_ item: ScheduledCourierReview) -> ScheduledCourierReviewView {
        return ScheduledCourierReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            windowDaysText: String(item.windowDays),
            checksum: item.checksum,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCourierReviewViews(_ items: [ScheduledCourierReview]) -> [ScheduledCourierReviewView] {
        var views: [ScheduledCourierReviewView] = []
        for item in items {
            views.append(toScheduledCourierReviewView(item))
        }
        return views
    }

    static func sumScheduledCourierReviewView(_ view: ScheduledCourierReviewView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedWindowDays) + parsedCeiling
    }
}
