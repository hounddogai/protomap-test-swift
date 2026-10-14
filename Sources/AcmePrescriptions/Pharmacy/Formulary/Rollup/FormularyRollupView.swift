import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary rollup.
    final class FormularyRollupView {
        var codeText: String
        var title: String
        var patientRefText: String
        var priority: String
        var graceDays: String
        var procedureCode: String
        var expiresAtText: String
        var segment: String
        var label: String
        var updatedAt: String
        var unit: String
        var statusLabel: String

        init(codeText: String, title: String, patientRefText: String, priority: String, graceDays: String, procedureCode: String, expiresAtText: String, segment: String, label: String, updatedAt: String, unit: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.patientRefText = patientRefText
            self.priority = priority
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.expiresAtText = expiresAtText
            self.segment = segment
            self.label = label
            self.updatedAt = updatedAt
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyRollupView(_ item: FormularyRollup) -> FormularyRollupView {
        return FormularyRollupView(
            codeText: item.code,
            title: item.title,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 120),
            priority: String(item.priority),
            graceDays: String(item.graceDays),
            procedureCode: item.procedureCode,
            expiresAtText: String(item.expiresAt),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            label: item.label,
            updatedAt: String(item.updatedAt),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyRollupViews(_ items: [FormularyRollup]) -> [FormularyRollupView] {
        var views: [FormularyRollupView] = []
        for item in items {
            views.append(toFormularyRollupView(item))
        }
        return views
    }

    static func sumFormularyRollupView(_ view: FormularyRollupView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedPriority) + Double(parsedGraceDays) + Double(parsedExpiresAt)
    }
}
