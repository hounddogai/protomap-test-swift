import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal baseline.
    final class GoalBaselineView {
        var codeText: String
        var name: String
        var diagnosisCodeText: String
        var currency: String
        var maximum: String
        var payer: String
        var retries: String
        var capacityText: String
        var version: String
        var segment: String
        var revisionText: String
        var statusLabel: String

        init(codeText: String, name: String, diagnosisCodeText: String, currency: String, maximum: String, payer: String, retries: String, capacityText: String, version: String, segment: String, revisionText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.diagnosisCodeText = diagnosisCodeText
            self.currency = currency
            self.maximum = maximum
            self.payer = payer
            self.retries = retries
            self.capacityText = capacityText
            self.version = version
            self.segment = segment
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toGoalBaselineView(_ item: GoalBaseline) -> GoalBaselineView {
        return GoalBaselineView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            currency: item.currency,
            maximum: String(format: "%.2f", item.maximum),
            payer: item.payer,
            retries: String(item.retries),
            capacityText: String(item.capacity),
            version: String(item.version),
            segment: item.segment,
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalBaselineViews(_ items: [GoalBaseline]) -> [GoalBaselineView] {
        var views: [GoalBaselineView] = []
        for item in items {
            views.append(toGoalBaselineView(item))
        }
        return views
    }

    static func sumGoalBaselineView(_ view: GoalBaselineView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedMaximum + Double(parsedRetries) + Double(parsedCapacity)
    }
}
