import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a lenient closure milestone.
    final class LenientClosureMilestoneView {
        var code: String
        var title: String
        var unit: String
        var quantity: String
        var startsAt: String
        var regionText: String
        var acuity: String
        var threshold: String
        var facility: String
        var wardText: String
        var statusLabel: String

        init(code: String, title: String, unit: String, quantity: String, startsAt: String, regionText: String, acuity: String, threshold: String, facility: String, wardText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.unit = unit
            self.quantity = quantity
            self.startsAt = startsAt
            self.regionText = regionText
            self.acuity = acuity
            self.threshold = threshold
            self.facility = facility
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientClosureMilestoneView(_ item: LenientClosureMilestone) -> LenientClosureMilestoneView {
        return LenientClosureMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            unit: item.unit,
            quantity: String(item.quantity),
            startsAt: String(item.startsAt),
            regionText: item.region,
            acuity: String(item.acuity),
            threshold: String(format: "%.2f", item.threshold),
            facility: item.facility,
            wardText: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientClosureMilestoneViews(_ items: [LenientClosureMilestone]) -> [LenientClosureMilestoneView] {
        var views: [LenientClosureMilestoneView] = []
        for item in items {
            views.append(toLenientClosureMilestoneView(item))
        }
        return views
    }

    static func sumLenientClosureMilestoneView(_ view: LenientClosureMilestoneView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedQuantity) + Double(parsedStartsAt) + Double(parsedAcuity)
    }
}
