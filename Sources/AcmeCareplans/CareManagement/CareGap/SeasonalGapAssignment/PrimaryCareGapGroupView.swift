import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a primary care gap group.
    final class PrimaryCareGapGroupView {
        var code: String
        var label: String
        var payer: String
        var procedureCodeText: String
        var category: String
        var version: String
        var timezone: String
        var createdAtText: String
        var startsAt: String
        var reviewerText: String
        var statusLabel: String

        init(code: String, label: String, payer: String, procedureCodeText: String, category: String, version: String, timezone: String, createdAtText: String, startsAt: String, reviewerText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payer = payer
            self.procedureCodeText = procedureCodeText
            self.category = category
            self.version = version
            self.timezone = timezone
            self.createdAtText = createdAtText
            self.startsAt = startsAt
            self.reviewerText = reviewerText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCareGapGroupView(_ item: PrimaryCareGapGroup) -> PrimaryCareGapGroupView {
        return PrimaryCareGapGroupView(
            code: item.code,
            label: item.label,
            payer: Kit.Text.truncate(item.payer, limit: 80),
            procedureCodeText: item.procedureCode,
            category: item.category,
            version: String(item.version),
            timezone: item.timezone,
            createdAtText: String(item.createdAt),
            startsAt: String(item.startsAt),
            reviewerText: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCareGapGroupViews(_ items: [PrimaryCareGapGroup]) -> [PrimaryCareGapGroupView] {
        var views: [PrimaryCareGapGroupView] = []
        for item in items {
            views.append(toPrimaryCareGapGroupView(item))
        }
        return views
    }

    static func sumPrimaryCareGapGroupView(_ view: PrimaryCareGapGroupView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedVersion) + Double(parsedCreatedAt) + Double(parsedStartsAt)
    }
}
