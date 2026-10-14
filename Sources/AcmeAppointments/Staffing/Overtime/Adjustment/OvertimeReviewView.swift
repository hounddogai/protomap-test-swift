import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime review.
    final class OvertimeReviewView {
        var code: String
        var name: String
        var ratioText: String
        var titleText: String
        var rateText: String
        var wardText: String
        var checksumText: String
        var attempts: String
        var timezone: String
        var statusLabel: String

        init(code: String, name: String, ratioText: String, titleText: String, rateText: String, wardText: String, checksumText: String, attempts: String, timezone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratioText = ratioText
            self.titleText = titleText
            self.rateText = rateText
            self.wardText = wardText
            self.checksumText = checksumText
            self.attempts = attempts
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeReviewView(_ item: OvertimeReview) -> OvertimeReviewView {
        return OvertimeReviewView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            ratioText: String(format: "%.2f", item.ratio),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            rateText: String(format: "%.2f", item.rate),
            wardText: Kit.Text.truncate(item.ward, limit: 80),
            checksumText: Kit.Text.truncate(item.checksum, limit: 40),
            attempts: String(item.attempts),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeReviewViews(_ items: [OvertimeReview]) -> [OvertimeReviewView] {
        var views: [OvertimeReviewView] = []
        for item in items {
            views.append(toOvertimeReviewView(item))
        }
        return views
    }

    static func sumOvertimeReviewView(_ view: OvertimeReviewView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedRatio + parsedRate + Double(parsedAttempts)
    }
}
