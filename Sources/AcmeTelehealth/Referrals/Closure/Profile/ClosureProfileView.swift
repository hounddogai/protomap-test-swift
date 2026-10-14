import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure profile.
    final class ClosureProfileView {
        var code: String
        var title: String
        var windowDays: String
        var batchSize: String
        var unit: String
        var phone: String
        var pinned: String
        var cost: String
        var dosageMg: String
        var discount: String
        var statusLabel: String

        init(code: String, title: String, windowDays: String, batchSize: String, unit: String, phone: String, pinned: String, cost: String, dosageMg: String, discount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.unit = unit
            self.phone = phone
            self.pinned = pinned
            self.cost = cost
            self.dosageMg = dosageMg
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toClosureProfileView(_ item: ClosureProfile) -> ClosureProfileView {
        return ClosureProfileView(
            code: item.code,
            title: item.title,
            windowDays: String(item.windowDays),
            batchSize: String(item.batchSize),
            unit: item.unit,
            phone: item.phone,
            pinned: "\(item.pinned)",
            cost: String(format: "%.2f", item.cost),
            dosageMg: String(format: "%.2f", item.dosageMg),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureProfileViews(_ items: [ClosureProfile]) -> [ClosureProfileView] {
        var views: [ClosureProfileView] = []
        for item in items {
            views.append(toClosureProfileView(item))
        }
        return views
    }

    static func sumClosureProfileView(_ view: ClosureProfileView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedBatchSize) + parsedCost
    }
}
