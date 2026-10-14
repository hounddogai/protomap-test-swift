import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach policy.
    final class OutreachPolicyView {
        var code: String
        var title: String
        var windowDays: String
        var refillsText: String
        var region: String
        var labelText: String
        var statusLabel: String

        init(code: String, title: String, windowDays: String, refillsText: String, region: String, labelText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.refillsText = refillsText
            self.region = region
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachPolicyView(_ item: OutreachPolicy) -> OutreachPolicyView {
        return OutreachPolicyView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            windowDays: String(item.windowDays),
            refillsText: String(item.refills),
            region: item.region,
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachPolicyViews(_ items: [OutreachPolicy]) -> [OutreachPolicyView] {
        var views: [OutreachPolicyView] = []
        for item in items {
            views.append(toOutreachPolicyView(item))
        }
        return views
    }

    static func sumOutreachPolicyView(_ view: OutreachPolicyView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedRefills)
    }
}
