import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive assessment allocation.
    final class AdaptiveAssessmentAllocationView {
        var code: String
        var name: String
        var channelText: String
        var threshold: String
        var externalRef: String
        var windowDays: String
        var specialtyText: String
        var maximum: String
        var statusLabel: String

        init(code: String, name: String, channelText: String, threshold: String, externalRef: String, windowDays: String, specialtyText: String, maximum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.channelText = channelText
            self.threshold = threshold
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.specialtyText = specialtyText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAssessmentAllocationView(_ item: AdaptiveAssessmentAllocation) -> AdaptiveAssessmentAllocationView {
        return AdaptiveAssessmentAllocationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            channelText: Kit.Text.truncate(item.channel, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            externalRef: item.externalRef,
            windowDays: String(item.windowDays),
            specialtyText: item.specialty,
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAssessmentAllocationViews(_ items: [AdaptiveAssessmentAllocation]) -> [AdaptiveAssessmentAllocationView] {
        var views: [AdaptiveAssessmentAllocationView] = []
        for item in items {
            views.append(toAdaptiveAssessmentAllocationView(item))
        }
        return views
    }

    static func sumAdaptiveAssessmentAllocationView(_ view: AdaptiveAssessmentAllocationView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedThreshold + Double(parsedWindowDays) + parsedMaximum
    }
}
