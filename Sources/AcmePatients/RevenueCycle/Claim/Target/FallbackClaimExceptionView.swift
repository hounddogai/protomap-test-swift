import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a fallback claim exception.
    final class FallbackClaimExceptionView {
        var code: String
        var label: String
        var specialtyText: String
        var active: String
        var priority: String
        var name: String
        var budget: String
        var allergyText: String
        var rate: String
        var contactEmail: String
        var weight: String
        var statusLabel: String

        init(code: String, label: String, specialtyText: String, active: String, priority: String, name: String, budget: String, allergyText: String, rate: String, contactEmail: String, weight: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.specialtyText = specialtyText
            self.active = active
            self.priority = priority
            self.name = name
            self.budget = budget
            self.allergyText = allergyText
            self.rate = rate
            self.contactEmail = contactEmail
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackClaimExceptionView(_ item: FallbackClaimException) -> FallbackClaimExceptionView {
        return FallbackClaimExceptionView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            specialtyText: item.specialty,
            active: "\(item.active)",
            priority: String(item.priority),
            name: Kit.Text.truncate(item.name, limit: 120),
            budget: String(format: "%.2f", item.budget),
            allergyText: item.allergy,
            rate: String(format: "%.2f", item.rate),
            contactEmail: item.contactEmail,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackClaimExceptionViews(_ items: [FallbackClaimException]) -> [FallbackClaimExceptionView] {
        var views: [FallbackClaimExceptionView] = []
        for item in items {
            views.append(toFallbackClaimExceptionView(item))
        }
        return views
    }

    static func sumFallbackClaimExceptionView(_ view: FallbackClaimExceptionView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedPriority) + parsedBudget + parsedRate
    }
}
