import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive dispense segment.
    final class AdaptiveDispenseSegmentView {
        var code: String
        var name: String
        var budget: String
        var currency: String
        var procedureCode: String
        var weightText: String
        var region: String
        var version: String
        var statusLabel: String

        init(code: String, name: String, budget: String, currency: String, procedureCode: String, weightText: String, region: String, version: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budget = budget
            self.currency = currency
            self.procedureCode = procedureCode
            self.weightText = weightText
            self.region = region
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDispenseSegmentView(_ item: AdaptiveDispenseSegment) -> AdaptiveDispenseSegmentView {
        return AdaptiveDispenseSegmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            budget: String(format: "%.2f", item.budget),
            currency: Kit.Text.truncate(item.currency, limit: 80),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            weightText: String(format: "%.2f", item.weight),
            region: item.region,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDispenseSegmentViews(_ items: [AdaptiveDispenseSegment]) -> [AdaptiveDispenseSegmentView] {
        var views: [AdaptiveDispenseSegmentView] = []
        for item in items {
            views.append(toAdaptiveDispenseSegmentView(item))
        }
        return views
    }

    static func sumAdaptiveDispenseSegmentView(_ view: AdaptiveDispenseSegmentView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedBudget + parsedWeight + Double(parsedVersion)
    }
}
