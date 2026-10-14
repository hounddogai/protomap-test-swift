import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix score.
    final class SkillMixScoreView {
        var code: String
        var name: String
        var ratio: String
        var amount: String
        var contactEmail: String
        var limit: String
        var durationMinutes: String
        var expiresAt: String
        var category: String
        var facilityText: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, ratio: String, amount: String, contactEmail: String, limit: String, durationMinutes: String, expiresAt: String, category: String, facilityText: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.amount = amount
            self.contactEmail = contactEmail
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.category = category
            self.facilityText = facilityText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixScoreView(_ item: SkillMixScore) -> SkillMixScoreView {
        return SkillMixScoreView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            amount: String(format: "%.2f", item.amount),
            contactEmail: item.contactEmail,
            limit: String(item.limit),
            durationMinutes: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            category: item.category,
            facilityText: item.facility,
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixScoreViews(_ items: [SkillMixScore]) -> [SkillMixScoreView] {
        var views: [SkillMixScoreView] = []
        for item in items {
            views.append(toSkillMixScoreView(item))
        }
        return views
    }

    static func sumSkillMixScoreView(_ view: SkillMixScoreView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedRatio + parsedAmount + Double(parsedLimit)
    }
}
