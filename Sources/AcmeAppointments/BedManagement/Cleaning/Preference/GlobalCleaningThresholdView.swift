import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global cleaning threshold.
    final class GlobalCleaningThresholdView {
        var code: String
        var label: String
        var retries: String
        var cost: String
        var summaryText: String
        var active: String
        var bedText: String
        var discount: String
        var statusLabel: String

        init(code: String, label: String, retries: String, cost: String, summaryText: String, active: String, bedText: String, discount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.retries = retries
            self.cost = cost
            self.summaryText = summaryText
            self.active = active
            self.bedText = bedText
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCleaningThresholdView(_ item: GlobalCleaningThreshold) -> GlobalCleaningThresholdView {
        return GlobalCleaningThresholdView(
            code: item.code,
            label: item.label,
            retries: String(item.retries),
            cost: String(format: "%.2f", item.cost),
            summaryText: item.summary,
            active: "\(item.active)",
            bedText: item.bed,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCleaningThresholdViews(_ items: [GlobalCleaningThreshold]) -> [GlobalCleaningThresholdView] {
        var views: [GlobalCleaningThresholdView] = []
        for item in items {
            views.append(toGlobalCleaningThresholdView(item))
        }
        return views
    }

    static func sumGlobalCleaningThresholdView(_ view: GlobalCleaningThresholdView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedRetries) + parsedCost + parsedDiscount
    }
}
