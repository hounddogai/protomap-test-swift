import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback program metric.
    final class FallbackProgramMetricView {
        var code: String
        var name: String
        var cost: String
        var revision: String
        var priority: String
        var patientRef: String
        var locale: String
        var attempts: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, name: String, cost: String, revision: String, priority: String, patientRef: String, locale: String, attempts: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.revision = revision
            self.priority = priority
            self.patientRef = patientRef
            self.locale = locale
            self.attempts = attempts
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackProgramMetricView(_ item: FallbackProgramMetric) -> FallbackProgramMetricView {
        return FallbackProgramMetricView(
            code: item.code,
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            revision: String(item.revision),
            priority: String(item.priority),
            patientRef: item.patientRef,
            locale: Kit.Text.truncate(item.locale, limit: 80),
            attempts: String(item.attempts),
            externalRefText: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackProgramMetricViews(_ items: [FallbackProgramMetric]) -> [FallbackProgramMetricView] {
        var views: [FallbackProgramMetricView] = []
        for item in items {
            views.append(toFallbackProgramMetricView(item))
        }
        return views
    }

    static func sumFallbackProgramMetricView(_ view: FallbackProgramMetricView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedCost + Double(parsedRevision) + Double(parsedPriority)
    }
}
