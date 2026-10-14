import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census plan.
    final class CensusPlanView {
        var code: String
        var title: String
        var encounterIDText: String
        var minimumText: String
        var notes: String
        var durationMinutes: String
        var payerText: String
        var statusLabel: String

        init(code: String, title: String, encounterIDText: String, minimumText: String, notes: String, durationMinutes: String, payerText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.encounterIDText = encounterIDText
            self.minimumText = minimumText
            self.notes = notes
            self.durationMinutes = durationMinutes
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusPlanView(_ item: CensusPlan) -> CensusPlanView {
        return CensusPlanView(
            code: item.code,
            title: item.title,
            encounterIDText: item.encounterID,
            minimumText: String(format: "%.2f", item.minimum),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            durationMinutes: String(item.durationMinutes),
            payerText: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusPlanViews(_ items: [CensusPlan]) -> [CensusPlanView] {
        var views: [CensusPlanView] = []
        for item in items {
            views.append(toCensusPlanView(item))
        }
        return views
    }

    static func sumCensusPlanView(_ view: CensusPlanView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedMinimum + Double(parsedDurationMinutes)
    }
}
