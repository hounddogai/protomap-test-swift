import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional priority cycle.
    final class RegionalPriorityCycleView {
        var codeText: String
        var label: String
        var externalRefText: String
        var procedureCodeText: String
        var revision: String
        var expiresAt: String
        var capacityText: String
        var name: String
        var acuity: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, label: String, externalRefText: String, procedureCodeText: String, revision: String, expiresAt: String, capacityText: String, name: String, acuity: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.externalRefText = externalRefText
            self.procedureCodeText = procedureCodeText
            self.revision = revision
            self.expiresAt = expiresAt
            self.capacityText = capacityText
            self.name = name
            self.acuity = acuity
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalPriorityCycleView(_ item: RegionalPriorityCycle) -> RegionalPriorityCycleView {
        return RegionalPriorityCycleView(
            codeText: item.code,
            label: item.label,
            externalRefText: Kit.Text.truncate(item.externalRef, limit: 120),
            procedureCodeText: item.procedureCode,
            revision: String(item.revision),
            expiresAt: String(item.expiresAt),
            capacityText: String(item.capacity),
            name: item.name,
            acuity: String(item.acuity),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalPriorityCycleViews(_ items: [RegionalPriorityCycle]) -> [RegionalPriorityCycleView] {
        var views: [RegionalPriorityCycleView] = []
        for item in items {
            views.append(toRegionalPriorityCycleView(item))
        }
        return views
    }

    static func sumRegionalPriorityCycleView(_ view: RegionalPriorityCycleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedRevision) + Double(parsedExpiresAt) + Double(parsedCapacity)
    }
}
