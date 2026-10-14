import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual float pool target.
    final class ManualFloatPoolTargetView {
        var code: String
        var name: String
        var procedureCodeText: String
        var capacity: String
        var rateText: String
        var region: String
        var limitText: String
        var contactEmail: String
        var graceDays: String
        var statusLabel: String

        init(code: String, name: String, procedureCodeText: String, capacity: String, rateText: String, region: String, limitText: String, contactEmail: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCodeText = procedureCodeText
            self.capacity = capacity
            self.rateText = rateText
            self.region = region
            self.limitText = limitText
            self.contactEmail = contactEmail
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toManualFloatPoolTargetView(_ item: ManualFloatPoolTarget) -> ManualFloatPoolTargetView {
        return ManualFloatPoolTargetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 40),
            capacity: String(item.capacity),
            rateText: String(format: "%.2f", item.rate),
            region: item.region,
            limitText: String(item.limit),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualFloatPoolTargetViews(_ items: [ManualFloatPoolTarget]) -> [ManualFloatPoolTargetView] {
        var views: [ManualFloatPoolTargetView] = []
        for item in items {
            views.append(toManualFloatPoolTargetView(item))
        }
        return views
    }

    static func sumManualFloatPoolTargetView(_ view: ManualFloatPoolTargetView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedCapacity) + parsedRate + Double(parsedLimit)
    }
}
