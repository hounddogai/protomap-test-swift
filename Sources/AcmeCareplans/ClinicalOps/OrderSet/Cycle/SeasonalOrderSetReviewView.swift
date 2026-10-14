import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal order set review.
    final class SeasonalOrderSetReviewView {
        var codeText: String
        var title: String
        var attemptsText: String
        var phone: String
        var version: String
        var ratioText: String
        var statusLabel: String

        init(codeText: String, title: String, attemptsText: String, phone: String, version: String, ratioText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.attemptsText = attemptsText
            self.phone = phone
            self.version = version
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalOrderSetReviewView(_ item: SeasonalOrderSetReview) -> SeasonalOrderSetReviewView {
        return SeasonalOrderSetReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            attemptsText: String(item.attempts),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            version: String(item.version),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalOrderSetReviewViews(_ items: [SeasonalOrderSetReview]) -> [SeasonalOrderSetReviewView] {
        var views: [SeasonalOrderSetReviewView] = []
        for item in items {
            views.append(toSeasonalOrderSetReviewView(item))
        }
        return views
    }

    static func sumSeasonalOrderSetReviewView(_ view: SeasonalOrderSetReviewView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedAttempts) + Double(parsedVersion) + parsedRatio
    }
}
