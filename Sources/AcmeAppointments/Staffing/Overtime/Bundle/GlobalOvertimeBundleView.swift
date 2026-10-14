import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global overtime bundle.
    final class GlobalOvertimeBundleView {
        var code: String
        var title: String
        var clinicianID: String
        var refillsText: String
        var floorValue: String
        var endsAt: String
        var payerText: String
        var category: String
        var priority: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, refillsText: String, floorValue: String, endsAt: String, payerText: String, category: String, priority: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.refillsText = refillsText
            self.floorValue = floorValue
            self.endsAt = endsAt
            self.payerText = payerText
            self.category = category
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalOvertimeBundleView(_ item: GlobalOvertimeBundle) -> GlobalOvertimeBundleView {
        return GlobalOvertimeBundleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 80),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            refillsText: String(item.refills),
            floorValue: String(format: "%.2f", item.floorValue),
            endsAt: String(item.endsAt),
            payerText: Kit.Text.truncate(item.payer, limit: 40),
            category: item.category,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalOvertimeBundleViews(_ items: [GlobalOvertimeBundle]) -> [GlobalOvertimeBundleView] {
        var views: [GlobalOvertimeBundleView] = []
        for item in items {
            views.append(toGlobalOvertimeBundleView(item))
        }
        return views
    }

    static func sumGlobalOvertimeBundleView(_ view: GlobalOvertimeBundleView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRefills) + parsedFloorValue + Double(parsedEndsAt)
    }
}
