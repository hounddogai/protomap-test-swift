import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert template.
    final class AlertTemplateView {
        var codeText: String
        var name: String
        var refills: String
        var priority: String
        var cost: String
        var description: String
        var batchSize: String
        var activeText: String
        var localeText: String
        var sequenceText: String
        var statusLabel: String

        init(codeText: String, name: String, refills: String, priority: String, cost: String, description: String, batchSize: String, activeText: String, localeText: String, sequenceText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.refills = refills
            self.priority = priority
            self.cost = cost
            self.description = description
            self.batchSize = batchSize
            self.activeText = activeText
            self.localeText = localeText
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toAlertTemplateView(_ item: AlertTemplate) -> AlertTemplateView {
        return AlertTemplateView(
            codeText: item.code,
            name: item.name,
            refills: String(item.refills),
            priority: String(item.priority),
            cost: String(format: "%.2f", item.cost),
            description: item.description,
            batchSize: String(item.batchSize),
            activeText: "\(item.active)",
            localeText: item.locale,
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertTemplateViews(_ items: [AlertTemplate]) -> [AlertTemplateView] {
        var views: [AlertTemplateView] = []
        for item in items {
            views.append(toAlertTemplateView(item))
        }
        return views
    }

    static func sumAlertTemplateView(_ view: AlertTemplateView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedRefills) + Double(parsedPriority) + parsedCost
    }
}
