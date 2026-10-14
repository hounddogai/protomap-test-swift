import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness claim.
    final class WitnessClaimView {
        var code: String
        var label: String
        var rateText: String
        var capacity: String
        var notes: String
        var name: String
        var costText: String
        var facility: String
        var statusLabel: String

        init(code: String, label: String, rateText: String, capacity: String, notes: String, name: String, costText: String, facility: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rateText = rateText
            self.capacity = capacity
            self.notes = notes
            self.name = name
            self.costText = costText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessClaimView(_ item: WitnessClaim) -> WitnessClaimView {
        return WitnessClaimView(
            code: item.code,
            label: item.label,
            rateText: String(format: "%.2f", item.rate),
            capacity: String(item.capacity),
            notes: item.notes,
            name: item.name,
            costText: String(format: "%.2f", item.cost),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessClaimViews(_ items: [WitnessClaim]) -> [WitnessClaimView] {
        var views: [WitnessClaimView] = []
        for item in items {
            views.append(toWitnessClaimView(item))
        }
        return views
    }

    static func sumWitnessClaimView(_ view: WitnessClaimView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedRate + Double(parsedCapacity) + parsedCost
    }
}
