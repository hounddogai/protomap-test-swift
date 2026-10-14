import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix review.
    final class SkillMixReviewView {
        var code: String
        var nameText: String
        var descriptionText: String
        var attempts: String
        var windowDays: String
        var bedText: String
        var refills: String
        var encounterID: String
        var procedureCode: String
        var visitMinutesText: String
        var visibleText: String
        var statusLabel: String

        init(code: String, nameText: String, descriptionText: String, attempts: String, windowDays: String, bedText: String, refills: String, encounterID: String, procedureCode: String, visitMinutesText: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.descriptionText = descriptionText
            self.attempts = attempts
            self.windowDays = windowDays
            self.bedText = bedText
            self.refills = refills
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.visitMinutesText = visitMinutesText
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixReviewView(_ item: SkillMixReview) -> SkillMixReviewView {
        return SkillMixReviewView(
            code: item.code,
            nameText: item.name,
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            attempts: String(item.attempts),
            windowDays: String(item.windowDays),
            bedText: Kit.Text.truncate(item.bed, limit: 64),
            refills: String(item.refills),
            encounterID: item.encounterID,
            procedureCode: item.procedureCode,
            visitMinutesText: String(item.visitMinutes),
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixReviewViews(_ items: [SkillMixReview]) -> [SkillMixReviewView] {
        var views: [SkillMixReviewView] = []
        for item in items {
            views.append(toSkillMixReviewView(item))
        }
        return views
    }

    static func sumSkillMixReviewView(_ view: SkillMixReviewView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedAttempts) + Double(parsedWindowDays) + Double(parsedRefills)
    }
}
