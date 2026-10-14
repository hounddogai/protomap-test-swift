import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted dispense cycle.
    final class WeightedDispenseCycleView {
        var code: String
        var title: String
        var visitMinutesText: String
        var label: String
        var budget: String
        var ownerIDText: String
        var rate: String
        var reviewer: String
        var acuity: String
        var ratio: String
        var channelText: String
        var statusLabel: String

        init(code: String, title: String, visitMinutesText: String, label: String, budget: String, ownerIDText: String, rate: String, reviewer: String, acuity: String, ratio: String, channelText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.label = label
            self.budget = budget
            self.ownerIDText = ownerIDText
            self.rate = rate
            self.reviewer = reviewer
            self.acuity = acuity
            self.ratio = ratio
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedDispenseCycleView(_ item: WeightedDispenseCycle) -> WeightedDispenseCycleView {
        return WeightedDispenseCycleView(
            code: item.code,
            title: item.title,
            visitMinutesText: String(item.visitMinutes),
            label: Kit.Text.truncate(item.label, limit: 64),
            budget: String(format: "%.2f", item.budget),
            ownerIDText: item.ownerID,
            rate: String(format: "%.2f", item.rate),
            reviewer: item.reviewer,
            acuity: String(item.acuity),
            ratio: String(format: "%.2f", item.ratio),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedDispenseCycleViews(_ items: [WeightedDispenseCycle]) -> [WeightedDispenseCycleView] {
        var views: [WeightedDispenseCycleView] = []
        for item in items {
            views.append(toWeightedDispenseCycleView(item))
        }
        return views
    }

    static func sumWeightedDispenseCycleView(_ view: WeightedDispenseCycleView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedVisitMinutes) + parsedBudget + parsedRate
    }
}
