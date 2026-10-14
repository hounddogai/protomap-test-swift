import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance record.
    final class RemittanceRecordView {
        var code: String
        var label: String
        var budget: String
        var bedText: String
        var country: String
        var rate: String
        var capacity: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, budget: String, bedText: String, country: String, rate: String, capacity: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.budget = budget
            self.bedText = bedText
            self.country = country
            self.rate = rate
            self.capacity = capacity
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceRecordView(_ item: RemittanceRecord) -> RemittanceRecordView {
        return RemittanceRecordView(
            code: item.code,
            label: item.label,
            budget: String(format: "%.2f", item.budget),
            bedText: item.bed,
            country: item.country,
            rate: String(format: "%.2f", item.rate),
            capacity: String(item.capacity),
            unit: Kit.Text.truncate(item.unit, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceRecordViews(_ items: [RemittanceRecord]) -> [RemittanceRecordView] {
        var views: [RemittanceRecordView] = []
        for item in items {
            views.append(toRemittanceRecordView(item))
        }
        return views
    }

    static func sumRemittanceRecordView(_ view: RemittanceRecordView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedBudget + parsedRate + Double(parsedCapacity)
    }
}
