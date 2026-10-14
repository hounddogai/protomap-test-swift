import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool schedule.
    final class FloatPoolScheduleView {
        var codeText: String
        var nameText: String
        var payer: String
        var dosageMg: String
        var margin: String
        var statusLabel: String

        init(codeText: String, nameText: String, payer: String, dosageMg: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.payer = payer
            self.dosageMg = dosageMg
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolScheduleView(_ item: FloatPoolSchedule) -> FloatPoolScheduleView {
        return FloatPoolScheduleView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            payer: item.payer,
            dosageMg: String(format: "%.2f", item.dosageMg),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolScheduleViews(_ items: [FloatPoolSchedule]) -> [FloatPoolScheduleView] {
        var views: [FloatPoolScheduleView] = []
        for item in items {
            views.append(toFloatPoolScheduleView(item))
        }
        return views
    }

    static func sumFloatPoolScheduleView(_ view: FloatPoolScheduleView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedDosageMg + parsedMargin
    }
}
