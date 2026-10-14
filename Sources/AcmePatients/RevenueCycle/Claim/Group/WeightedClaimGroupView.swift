import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted claim group.
    final class WeightedClaimGroupView {
        var codeText: String
        var title: String
        var maximumText: String
        var externalRef: String
        var retriesText: String
        var visibleText: String
        var facilityText: String
        var statusLabel: String

        init(codeText: String, title: String, maximumText: String, externalRef: String, retriesText: String, visibleText: String, facilityText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.maximumText = maximumText
            self.externalRef = externalRef
            self.retriesText = retriesText
            self.visibleText = visibleText
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedClaimGroupView(_ item: WeightedClaimGroup) -> WeightedClaimGroupView {
        return WeightedClaimGroupView(
            codeText: item.code,
            title: item.title,
            maximumText: String(format: "%.2f", item.maximum),
            externalRef: item.externalRef,
            retriesText: String(item.retries),
            visibleText: "\(item.visible)",
            facilityText: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedClaimGroupViews(_ items: [WeightedClaimGroup]) -> [WeightedClaimGroupView] {
        var views: [WeightedClaimGroupView] = []
        for item in items {
            views.append(toWeightedClaimGroupView(item))
        }
        return views
    }

    static func sumWeightedClaimGroupView(_ view: WeightedClaimGroupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedMaximum + Double(parsedRetries)
    }
}
