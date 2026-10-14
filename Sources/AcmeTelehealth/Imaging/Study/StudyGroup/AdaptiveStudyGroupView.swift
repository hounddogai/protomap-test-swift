import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive study group.
    final class AdaptiveStudyGroupView {
        var code: String
        var title: String
        var allergyText: String
        var segment: String
        var channelText: String
        var quantityText: String
        var statusLabel: String

        init(code: String, title: String, allergyText: String, segment: String, channelText: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.allergyText = allergyText
            self.segment = segment
            self.channelText = channelText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStudyGroupView(_ item: AdaptiveStudyGroup) -> AdaptiveStudyGroupView {
        return AdaptiveStudyGroupView(
            code: item.code,
            title: item.title,
            allergyText: item.allergy,
            segment: Kit.Text.truncate(item.segment, limit: 120),
            channelText: item.channel,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStudyGroupViews(_ items: [AdaptiveStudyGroup]) -> [AdaptiveStudyGroupView] {
        var views: [AdaptiveStudyGroupView] = []
        for item in items {
            views.append(toAdaptiveStudyGroupView(item))
        }
        return views
    }

    static func sumAdaptiveStudyGroupView(_ view: AdaptiveStudyGroupView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
