import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary entry.
    final class FormularyEntryView {
        var code: String
        var label: String
        var ceilingText: String
        var payerText: String
        var externalRef: String
        var summary: String
        var maximum: String
        var name: String
        var capacity: String
        var statusLabel: String

        init(code: String, label: String, ceilingText: String, payerText: String, externalRef: String, summary: String, maximum: String, name: String, capacity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceilingText = ceilingText
            self.payerText = payerText
            self.externalRef = externalRef
            self.summary = summary
            self.maximum = maximum
            self.name = name
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyEntryView(_ item: FormularyEntry) -> FormularyEntryView {
        return FormularyEntryView(
            code: item.code,
            label: item.label,
            ceilingText: String(format: "%.2f", item.ceiling),
            payerText: item.payer,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            summary: Kit.Text.truncate(item.summary, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            name: Kit.Text.truncate(item.name, limit: 120),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyEntryViews(_ items: [FormularyEntry]) -> [FormularyEntryView] {
        var views: [FormularyEntryView] = []
        for item in items {
            views.append(toFormularyEntryView(item))
        }
        return views
    }

    static func sumFormularyEntryView(_ view: FormularyEntryView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCeiling + parsedMaximum + Double(parsedCapacity)
    }
}
