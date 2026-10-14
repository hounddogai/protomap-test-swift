import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance plan.
    final class RemittancePlanView {
        var codeText: String
        var title: String
        var activeText: String
        var copay: String
        var ratio: String
        var source: String
        var weight: String
        var threshold: String
        var region: String
        var rate: String
        var margin: String
        var statusLabel: String

        init(codeText: String, title: String, activeText: String, copay: String, ratio: String, source: String, weight: String, threshold: String, region: String, rate: String, margin: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.activeText = activeText
            self.copay = copay
            self.ratio = ratio
            self.source = source
            self.weight = weight
            self.threshold = threshold
            self.region = region
            self.rate = rate
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRemittancePlanView(_ item: RemittancePlan) -> RemittancePlanView {
        return RemittancePlanView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            activeText: "\(item.active)",
            copay: String(format: "%.2f", item.copay),
            ratio: String(format: "%.2f", item.ratio),
            source: Kit.Text.truncate(item.source, limit: 64),
            weight: String(format: "%.2f", item.weight),
            threshold: String(format: "%.2f", item.threshold),
            region: item.region,
            rate: String(format: "%.2f", item.rate),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittancePlanViews(_ items: [RemittancePlan]) -> [RemittancePlanView] {
        var views: [RemittancePlanView] = []
        for item in items {
            views.append(toRemittancePlanView(item))
        }
        return views
    }

    static func sumRemittancePlanView(_ view: RemittancePlanView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedCopay + parsedRatio + parsedWeight
    }
}
