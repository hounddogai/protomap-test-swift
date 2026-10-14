import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool quota.
    final class FloatPoolQuotaView {
        var code: String
        var labelText: String
        var batchSizeText: String
        var ceiling: String
        var durationMinutes: String
        var visible: String
        var budgetText: String
        var statusLabel: String

        init(code: String, labelText: String, batchSizeText: String, ceiling: String, durationMinutes: String, visible: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.batchSizeText = batchSizeText
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.visible = visible
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolQuotaView(_ item: FloatPoolQuota) -> FloatPoolQuotaView {
        return FloatPoolQuotaView(
            code: item.code,
            labelText: item.label,
            batchSizeText: String(item.batchSize),
            ceiling: String(format: "%.2f", item.ceiling),
            durationMinutes: String(item.durationMinutes),
            visible: "\(item.visible)",
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolQuotaViews(_ items: [FloatPoolQuota]) -> [FloatPoolQuotaView] {
        var views: [FloatPoolQuotaView] = []
        for item in items {
            views.append(toFloatPoolQuotaView(item))
        }
        return views
    }

    static func sumFloatPoolQuotaView(_ view: FloatPoolQuotaView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedBatchSize) + parsedCeiling + Double(parsedDurationMinutes)
    }
}
