import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a adaptive witness group.
    final class AdaptiveWitnessGroupView {
        var code: String
        var title: String
        var specialty: String
        var channel: String
        var ratioText: String
        var allergy: String
        var priority: String
        var externalRefText: String
        var limitText: String
        var statusLabel: String

        init(code: String, title: String, specialty: String, channel: String, ratioText: String, allergy: String, priority: String, externalRefText: String, limitText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.channel = channel
            self.ratioText = ratioText
            self.allergy = allergy
            self.priority = priority
            self.externalRefText = externalRefText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveWitnessGroupView(_ item: AdaptiveWitnessGroup) -> AdaptiveWitnessGroupView {
        return AdaptiveWitnessGroupView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            specialty: item.specialty,
            channel: item.channel,
            ratioText: String(format: "%.2f", item.ratio),
            allergy: item.allergy,
            priority: String(item.priority),
            externalRefText: item.externalRef,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveWitnessGroupViews(_ items: [AdaptiveWitnessGroup]) -> [AdaptiveWitnessGroupView] {
        var views: [AdaptiveWitnessGroupView] = []
        for item in items {
            views.append(toAdaptiveWitnessGroupView(item))
        }
        return views
    }

    static func sumAdaptiveWitnessGroupView(_ view: AdaptiveWitnessGroupView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedRatio + Double(parsedPriority) + Double(parsedLimit)
    }
}
