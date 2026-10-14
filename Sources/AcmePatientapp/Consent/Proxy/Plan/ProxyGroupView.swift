import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy group.
    final class ProxyGroupView {
        var codeText: String
        var name: String
        var dosageMg: String
        var contactEmail: String
        var specialtyText: String
        var startsAt: String
        var windowDaysText: String
        var title: String
        var descriptionText: String
        var statusLabel: String

        init(codeText: String, name: String, dosageMg: String, contactEmail: String, specialtyText: String, startsAt: String, windowDaysText: String, title: String, descriptionText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.dosageMg = dosageMg
            self.contactEmail = contactEmail
            self.specialtyText = specialtyText
            self.startsAt = startsAt
            self.windowDaysText = windowDaysText
            self.title = title
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toProxyGroupView(_ item: ProxyGroup) -> ProxyGroupView {
        return ProxyGroupView(
            codeText: item.code,
            name: item.name,
            dosageMg: String(format: "%.2f", item.dosageMg),
            contactEmail: item.contactEmail,
            specialtyText: item.specialty,
            startsAt: String(item.startsAt),
            windowDaysText: String(item.windowDays),
            title: Kit.Text.truncate(item.title, limit: 80),
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyGroupViews(_ items: [ProxyGroup]) -> [ProxyGroupView] {
        var views: [ProxyGroupView] = []
        for item in items {
            views.append(toProxyGroupView(item))
        }
        return views
    }

    static func sumProxyGroupView(_ view: ProxyGroupView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedDosageMg + Double(parsedStartsAt) + Double(parsedWindowDays)
    }
}
