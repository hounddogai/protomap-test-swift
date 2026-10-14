import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a strict authorization entry.
    final class StrictAuthorizationEntryView {
        var code: String
        var label: String
        var createdAt: String
        var specialtyText: String
        var ownerID: String
        var allergy: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, specialtyText: String, ownerID: String, allergy: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.specialtyText = specialtyText
            self.ownerID = ownerID
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAuthorizationEntryView(_ item: StrictAuthorizationEntry) -> StrictAuthorizationEntryView {
        return StrictAuthorizationEntryView(
            code: item.code,
            label: item.label,
            createdAt: String(item.createdAt),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 40),
            ownerID: item.ownerID,
            allergy: Kit.Text.truncate(item.allergy, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAuthorizationEntryViews(_ items: [StrictAuthorizationEntry]) -> [StrictAuthorizationEntryView] {
        var views: [StrictAuthorizationEntryView] = []
        for item in items {
            views.append(toStrictAuthorizationEntryView(item))
        }
        return views
    }

    static func sumStrictAuthorizationEntryView(_ view: StrictAuthorizationEntryView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
