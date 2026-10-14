import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered statement adjustment.
    final class TieredStatementAdjustmentView {
        var code: String
        var labelText: String
        var dosageMg: String
        var visitMinutes: String
        var maximum: String
        var startsAt: String
        var statusLabel: String

        init(code: String, labelText: String, dosageMg: String, visitMinutes: String, maximum: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toTieredStatementAdjustmentView(_ item: TieredStatementAdjustment) -> TieredStatementAdjustmentView {
        return TieredStatementAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            dosageMg: String(format: "%.2f", item.dosageMg),
            visitMinutes: String(item.visitMinutes),
            maximum: String(format: "%.2f", item.maximum),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredStatementAdjustmentViews(_ items: [TieredStatementAdjustment]) -> [TieredStatementAdjustmentView] {
        var views: [TieredStatementAdjustmentView] = []
        for item in items {
            views.append(toTieredStatementAdjustmentView(item))
        }
        return views
    }

    static func sumTieredStatementAdjustmentView(_ view: TieredStatementAdjustmentView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedDosageMg + Double(parsedVisitMinutes) + parsedMaximum
    }
}
