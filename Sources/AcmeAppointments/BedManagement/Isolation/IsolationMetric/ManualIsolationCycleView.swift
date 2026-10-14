import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual isolation cycle.
    final class ManualIsolationCycleView {
        var codeText: String
        var name: String
        var discount: String
        var clinicianID: String
        var title: String
        var minimum: String
        var attempts: String
        var margin: String
        var labelText: String
        var statusLabel: String

        init(codeText: String, name: String, discount: String, clinicianID: String, title: String, minimum: String, attempts: String, margin: String, labelText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.discount = discount
            self.clinicianID = clinicianID
            self.title = title
            self.minimum = minimum
            self.attempts = attempts
            self.margin = margin
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toManualIsolationCycleView(_ item: ManualIsolationCycle) -> ManualIsolationCycleView {
        return ManualIsolationCycleView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            discount: String(format: "%.2f", item.discount),
            clinicianID: item.clinicianID,
            title: item.title,
            minimum: String(format: "%.2f", item.minimum),
            attempts: String(item.attempts),
            margin: String(format: "%.2f", item.margin),
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualIsolationCycleViews(_ items: [ManualIsolationCycle]) -> [ManualIsolationCycleView] {
        var views: [ManualIsolationCycleView] = []
        for item in items {
            views.append(toManualIsolationCycleView(item))
        }
        return views
    }

    static func sumManualIsolationCycleView(_ view: ManualIsolationCycleView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedDiscount + parsedMinimum + Double(parsedAttempts)
    }
}
