import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility segment.
    final class EligibilitySegmentView {
        var code: String
        var titleText: String
        var copay: String
        var timezone: String
        var expiresAt: String
        var name: String
        var activeText: String
        var createdAt: String
        var retries: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, titleText: String, copay: String, timezone: String, expiresAt: String, name: String, activeText: String, createdAt: String, retries: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.copay = copay
            self.timezone = timezone
            self.expiresAt = expiresAt
            self.name = name
            self.activeText = activeText
            self.createdAt = createdAt
            self.retries = retries
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilitySegmentView(_ item: EligibilitySegment) -> EligibilitySegmentView {
        return EligibilitySegmentView(
            code: item.code,
            titleText: item.title,
            copay: String(format: "%.2f", item.copay),
            timezone: item.timezone,
            expiresAt: String(item.expiresAt),
            name: Kit.Text.truncate(item.name, limit: 64),
            activeText: "\(item.active)",
            createdAt: String(item.createdAt),
            retries: String(item.retries),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilitySegmentViews(_ items: [EligibilitySegment]) -> [EligibilitySegmentView] {
        var views: [EligibilitySegmentView] = []
        for item in items {
            views.append(toEligibilitySegmentView(item))
        }
        return views
    }

    static func sumEligibilitySegmentView(_ view: EligibilitySegmentView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedCopay + Double(parsedExpiresAt) + Double(parsedCreatedAt)
    }
}
