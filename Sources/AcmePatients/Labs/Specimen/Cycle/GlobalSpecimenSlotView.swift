import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global specimen slot.
    final class GlobalSpecimenSlotView {
        var code: String
        var title: String
        var retries: String
        var cost: String
        var rate: String
        var statusLabel: String

        init(code: String, title: String, retries: String, cost: String, rate: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.retries = retries
            self.cost = cost
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSpecimenSlotView(_ item: GlobalSpecimenSlot) -> GlobalSpecimenSlotView {
        return GlobalSpecimenSlotView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            retries: String(item.retries),
            cost: String(format: "%.2f", item.cost),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSpecimenSlotViews(_ items: [GlobalSpecimenSlot]) -> [GlobalSpecimenSlotView] {
        var views: [GlobalSpecimenSlotView] = []
        for item in items {
            views.append(toGlobalSpecimenSlotView(item))
        }
        return views
    }

    static func sumGlobalSpecimenSlotView(_ view: GlobalSpecimenSlotView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRetries) + parsedCost + parsedRate
    }
}
