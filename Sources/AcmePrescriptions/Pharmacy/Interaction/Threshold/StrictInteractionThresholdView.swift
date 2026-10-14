import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict interaction threshold.
    final class StrictInteractionThresholdView {
        var codeText: String
        var name: String
        var reviewerText: String
        var bedText: String
        var pinnedText: String
        var capacity: String
        var label: String
        var margin: String
        var score: String
        var weightText: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, name: String, reviewerText: String, bedText: String, pinnedText: String, capacity: String, label: String, margin: String, score: String, weightText: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.reviewerText = reviewerText
            self.bedText = bedText
            self.pinnedText = pinnedText
            self.capacity = capacity
            self.label = label
            self.margin = margin
            self.score = score
            self.weightText = weightText
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictInteractionThresholdView(_ item: StrictInteractionThreshold) -> StrictInteractionThresholdView {
        return StrictInteractionThresholdView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            reviewerText: item.reviewer,
            bedText: item.bed,
            pinnedText: "\(item.pinned)",
            capacity: String(item.capacity),
            label: item.label,
            margin: String(format: "%.2f", item.margin),
            score: String(format: "%.2f", item.score),
            weightText: String(format: "%.2f", item.weight),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictInteractionThresholdViews(_ items: [StrictInteractionThreshold]) -> [StrictInteractionThresholdView] {
        var views: [StrictInteractionThresholdView] = []
        for item in items {
            views.append(toStrictInteractionThresholdView(item))
        }
        return views
    }

    static func sumStrictInteractionThresholdView(_ view: StrictInteractionThresholdView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedCapacity) + parsedMargin + parsedScore
    }
}
