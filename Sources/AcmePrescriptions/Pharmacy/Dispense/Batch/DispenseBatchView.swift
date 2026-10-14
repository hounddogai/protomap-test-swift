import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense batch.
    final class DispenseBatchView {
        var code: String
        var title: String
        var durationMinutes: String
        var acuity: String
        var budget: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, title: String, durationMinutes: String, acuity: String, budget: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.acuity = acuity
            self.budget = budget
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseBatchView(_ item: DispenseBatch) -> DispenseBatchView {
        return DispenseBatchView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            durationMinutes: String(item.durationMinutes),
            acuity: String(item.acuity),
            budget: String(format: "%.2f", item.budget),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseBatchViews(_ items: [DispenseBatch]) -> [DispenseBatchView] {
        var views: [DispenseBatchView] = []
        for item in items {
            views.append(toDispenseBatchView(item))
        }
        return views
    }

    static func sumDispenseBatchView(_ view: DispenseBatchView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedAcuity) + parsedBudget
    }
}
