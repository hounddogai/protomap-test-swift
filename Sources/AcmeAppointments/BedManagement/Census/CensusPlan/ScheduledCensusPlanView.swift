import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled census plan.
    final class ScheduledCensusPlanView {
        var code: String
        var title: String
        var procedureCodeText: String
        var batchSizeText: String
        var graceDays: String
        var specialty: String
        var priorityText: String
        var ward: String
        var unit: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, title: String, procedureCodeText: String, batchSizeText: String, graceDays: String, specialty: String, priorityText: String, ward: String, unit: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCodeText = procedureCodeText
            self.batchSizeText = batchSizeText
            self.graceDays = graceDays
            self.specialty = specialty
            self.priorityText = priorityText
            self.ward = ward
            self.unit = unit
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCensusPlanView(_ item: ScheduledCensusPlan) -> ScheduledCensusPlanView {
        return ScheduledCensusPlanView(
            code: item.code,
            title: item.title,
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 80),
            batchSizeText: String(item.batchSize),
            graceDays: String(item.graceDays),
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            priorityText: String(item.priority),
            ward: item.ward,
            unit: item.unit,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCensusPlanViews(_ items: [ScheduledCensusPlan]) -> [ScheduledCensusPlanView] {
        var views: [ScheduledCensusPlanView] = []
        for item in items {
            views.append(toScheduledCensusPlanView(item))
        }
        return views
    }

    static func sumScheduledCensusPlanView(_ view: ScheduledCensusPlanView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays) + Double(parsedPriority)
    }
}
