import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive overtime allocation.
    final class AdaptiveOvertimeAllocationView {
        var code: String
        var nameText: String
        var ceiling: String
        var graceDaysText: String
        var dosageMg: String
        var capacity: String
        var phone: String
        var retriesText: String
        var statusLabel: String

        init(code: String, nameText: String, ceiling: String, graceDaysText: String, dosageMg: String, capacity: String, phone: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ceiling = ceiling
            self.graceDaysText = graceDaysText
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.phone = phone
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveOvertimeAllocationView(_ item: AdaptiveOvertimeAllocation) -> AdaptiveOvertimeAllocationView {
        return AdaptiveOvertimeAllocationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            graceDaysText: String(item.graceDays),
            dosageMg: String(format: "%.2f", item.dosageMg),
            capacity: String(item.capacity),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveOvertimeAllocationViews(_ items: [AdaptiveOvertimeAllocation]) -> [AdaptiveOvertimeAllocationView] {
        var views: [AdaptiveOvertimeAllocationView] = []
        for item in items {
            views.append(toAdaptiveOvertimeAllocationView(item))
        }
        return views
    }

    static func sumAdaptiveOvertimeAllocationView(_ view: AdaptiveOvertimeAllocationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedCeiling + Double(parsedGraceDays) + parsedDosageMg
    }
}
