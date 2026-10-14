import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive claim template.
    final class AdaptiveClaimTemplateView {
        var codeText: String
        var name: String
        var contactEmail: String
        var specialtyText: String
        var ownerID: String
        var attempts: String
        var capacity: String
        var statusLabel: String

        init(codeText: String, name: String, contactEmail: String, specialtyText: String, ownerID: String, attempts: String, capacity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.contactEmail = contactEmail
            self.specialtyText = specialtyText
            self.ownerID = ownerID
            self.attempts = attempts
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveClaimTemplateView(_ item: AdaptiveClaimTemplate) -> AdaptiveClaimTemplateView {
        return AdaptiveClaimTemplateView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            contactEmail: item.contactEmail,
            specialtyText: item.specialty,
            ownerID: item.ownerID,
            attempts: String(item.attempts),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveClaimTemplateViews(_ items: [AdaptiveClaimTemplate]) -> [AdaptiveClaimTemplateView] {
        var views: [AdaptiveClaimTemplateView] = []
        for item in items {
            views.append(toAdaptiveClaimTemplateView(item))
        }
        return views
    }

    static func sumAdaptiveClaimTemplateView(_ view: AdaptiveClaimTemplateView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedAttempts) + Double(parsedCapacity)
    }
}
