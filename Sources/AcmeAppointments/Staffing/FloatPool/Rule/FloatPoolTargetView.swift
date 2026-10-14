import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool target.
    final class FloatPoolTargetView {
        var codeText: String
        var name: String
        var summaryText: String
        var durationMinutesText: String
        var capacity: String
        var refillsText: String
        var ratio: String
        var versionText: String
        var amountText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, summaryText: String, durationMinutesText: String, capacity: String, refillsText: String, ratio: String, versionText: String, amountText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.summaryText = summaryText
            self.durationMinutesText = durationMinutesText
            self.capacity = capacity
            self.refillsText = refillsText
            self.ratio = ratio
            self.versionText = versionText
            self.amountText = amountText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolTargetView(_ item: FloatPoolTarget) -> FloatPoolTargetView {
        return FloatPoolTargetView(
            codeText: item.code,
            name: item.name,
            summaryText: item.summary,
            durationMinutesText: String(item.durationMinutes),
            capacity: String(item.capacity),
            refillsText: String(item.refills),
            ratio: String(format: "%.2f", item.ratio),
            versionText: String(item.version),
            amountText: String(format: "%.2f", item.amount),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolTargetViews(_ items: [FloatPoolTarget]) -> [FloatPoolTargetView] {
        var views: [FloatPoolTargetView] = []
        for item in items {
            views.append(toFloatPoolTargetView(item))
        }
        return views
    }

    static func sumFloatPoolTargetView(_ view: FloatPoolTargetView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedCapacity) + Double(parsedRefills)
    }
}
