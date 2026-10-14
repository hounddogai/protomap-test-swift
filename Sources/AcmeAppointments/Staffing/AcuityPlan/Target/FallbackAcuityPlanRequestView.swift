import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback acuity plan request.
    final class FallbackAcuityPlanRequestView {
        var codeText: String
        var nameText: String
        var maximum: String
        var marginText: String
        var title: String
        var rateText: String
        var visible: String
        var statusLabel: String

        init(codeText: String, nameText: String, maximum: String, marginText: String, title: String, rateText: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.maximum = maximum
            self.marginText = marginText
            self.title = title
            self.rateText = rateText
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAcuityPlanRequestView(_ item: FallbackAcuityPlanRequest) -> FallbackAcuityPlanRequestView {
        return FallbackAcuityPlanRequestView(
            codeText: item.code,
            nameText: item.name,
            maximum: String(format: "%.2f", item.maximum),
            marginText: String(format: "%.2f", item.margin),
            title: item.title,
            rateText: String(format: "%.2f", item.rate),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAcuityPlanRequestViews(_ items: [FallbackAcuityPlanRequest]) -> [FallbackAcuityPlanRequestView] {
        var views: [FallbackAcuityPlanRequestView] = []
        for item in items {
            views.append(toFallbackAcuityPlanRequestView(item))
        }
        return views
    }

    static func sumFallbackAcuityPlanRequestView(_ view: FallbackAcuityPlanRequestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMaximum + parsedMargin + parsedRate
    }
}
