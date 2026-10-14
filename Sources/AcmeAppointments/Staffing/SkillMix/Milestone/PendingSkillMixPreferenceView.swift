import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending skill mix preference.
    final class PendingSkillMixPreferenceView {
        var code: String
        var title: String
        var rate: String
        var endsAt: String
        var notes: String
        var copayText: String
        var visitMinutes: String
        var facility: String
        var statusLabel: String

        init(code: String, title: String, rate: String, endsAt: String, notes: String, copayText: String, visitMinutes: String, facility: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.rate = rate
            self.endsAt = endsAt
            self.notes = notes
            self.copayText = copayText
            self.visitMinutes = visitMinutes
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toPendingSkillMixPreferenceView(_ item: PendingSkillMixPreference) -> PendingSkillMixPreferenceView {
        return PendingSkillMixPreferenceView(
            code: item.code,
            title: item.title,
            rate: String(format: "%.2f", item.rate),
            endsAt: String(item.endsAt),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            copayText: String(format: "%.2f", item.copay),
            visitMinutes: String(item.visitMinutes),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingSkillMixPreferenceViews(_ items: [PendingSkillMixPreference]) -> [PendingSkillMixPreferenceView] {
        var views: [PendingSkillMixPreferenceView] = []
        for item in items {
            views.append(toPendingSkillMixPreferenceView(item))
        }
        return views
    }

    static func sumPendingSkillMixPreferenceView(_ view: PendingSkillMixPreferenceView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedRate + Double(parsedEndsAt) + parsedCopay
    }
}
