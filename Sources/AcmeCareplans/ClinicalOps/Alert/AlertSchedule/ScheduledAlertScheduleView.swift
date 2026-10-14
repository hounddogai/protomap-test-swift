import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled alert schedule.
    final class ScheduledAlertScheduleView {
        var codeText: String
        var titleText: String
        var dosageMg: String
        var quantity: String
        var ratio: String
        var checksumText: String
        var procedureCodeText: String
        var discount: String
        var unitText: String
        var statusLabel: String

        init(codeText: String, titleText: String, dosageMg: String, quantity: String, ratio: String, checksumText: String, procedureCodeText: String, discount: String, unitText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.dosageMg = dosageMg
            self.quantity = quantity
            self.ratio = ratio
            self.checksumText = checksumText
            self.procedureCodeText = procedureCodeText
            self.discount = discount
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAlertScheduleView(_ item: ScheduledAlertSchedule) -> ScheduledAlertScheduleView {
        return ScheduledAlertScheduleView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            dosageMg: String(format: "%.2f", item.dosageMg),
            quantity: String(item.quantity),
            ratio: String(format: "%.2f", item.ratio),
            checksumText: item.checksum,
            procedureCodeText: item.procedureCode,
            discount: String(format: "%.2f", item.discount),
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAlertScheduleViews(_ items: [ScheduledAlertSchedule]) -> [ScheduledAlertScheduleView] {
        var views: [ScheduledAlertScheduleView] = []
        for item in items {
            views.append(toScheduledAlertScheduleView(item))
        }
        return views
    }

    static func sumScheduledAlertScheduleView(_ view: ScheduledAlertScheduleView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedDosageMg + Double(parsedQuantity) + parsedRatio
    }
}
