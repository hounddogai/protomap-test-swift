import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan exception.
    final class AcuityPlanExceptionView {
        var code: String
        var name: String
        var maximum: String
        var region: String
        var capacity: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, name: String, maximum: String, region: String, capacity: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.region = region
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanExceptionView(_ item: AcuityPlanException) -> AcuityPlanExceptionView {
        return AcuityPlanExceptionView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            region: item.region,
            capacity: String(item.capacity),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanExceptionViews(_ items: [AcuityPlanException]) -> [AcuityPlanExceptionView] {
        var views: [AcuityPlanExceptionView] = []
        for item in items {
            views.append(toAcuityPlanExceptionView(item))
        }
        return views
    }

    static func sumAcuityPlanExceptionView(_ view: AcuityPlanExceptionView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMaximum + Double(parsedCapacity) + Double(parsedUpdatedAt)
    }
}
