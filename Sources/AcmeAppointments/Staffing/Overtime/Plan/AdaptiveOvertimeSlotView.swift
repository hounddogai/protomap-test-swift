import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a adaptive overtime slot.
    final class AdaptiveOvertimeSlotView {
        var code: String
        var name: String
        var currency: String
        var startsAt: String
        var updatedAt: String
        var category: String
        var limit: String
        var retries: String
        var patientRef: String
        var activeText: String
        var label: String
        var statusLabel: String

        init(code: String, name: String, currency: String, startsAt: String, updatedAt: String, category: String, limit: String, retries: String, patientRef: String, activeText: String, label: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.currency = currency
            self.startsAt = startsAt
            self.updatedAt = updatedAt
            self.category = category
            self.limit = limit
            self.retries = retries
            self.patientRef = patientRef
            self.activeText = activeText
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveOvertimeSlotView(_ item: AdaptiveOvertimeSlot) -> AdaptiveOvertimeSlotView {
        return AdaptiveOvertimeSlotView(
            code: item.code,
            name: item.name,
            currency: Kit.Text.truncate(item.currency, limit: 80),
            startsAt: String(item.startsAt),
            updatedAt: String(item.updatedAt),
            category: item.category,
            limit: String(item.limit),
            retries: String(item.retries),
            patientRef: item.patientRef,
            activeText: "\(item.active)",
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveOvertimeSlotViews(_ items: [AdaptiveOvertimeSlot]) -> [AdaptiveOvertimeSlotView] {
        var views: [AdaptiveOvertimeSlotView] = []
        for item in items {
            views.append(toAdaptiveOvertimeSlotView(item))
        }
        return views
    }

    static func sumAdaptiveOvertimeSlotView(_ view: AdaptiveOvertimeSlotView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedUpdatedAt) + Double(parsedLimit)
    }
}
