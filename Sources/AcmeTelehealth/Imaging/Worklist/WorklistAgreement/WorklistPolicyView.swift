import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist policy.
    final class WorklistPolicyView {
        var code: String
        var name: String
        var bed: String
        var region: String
        var timezoneText: String
        var payer: String
        var thresholdText: String
        var startsAt: String
        var statusLabel: String

        init(code: String, name: String, bed: String, region: String, timezoneText: String, payer: String, thresholdText: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.bed = bed
            self.region = region
            self.timezoneText = timezoneText
            self.payer = payer
            self.thresholdText = thresholdText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistPolicyView(_ item: WorklistPolicy) -> WorklistPolicyView {
        return WorklistPolicyView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 40),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            region: item.region,
            timezoneText: item.timezone,
            payer: item.payer,
            thresholdText: String(format: "%.2f", item.threshold),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistPolicyViews(_ items: [WorklistPolicy]) -> [WorklistPolicyView] {
        var views: [WorklistPolicyView] = []
        for item in items {
            views.append(toWorklistPolicyView(item))
        }
        return views
    }

    static func sumWorklistPolicyView(_ view: WorklistPolicyView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedThreshold + Double(parsedStartsAt)
    }
}
