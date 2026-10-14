import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched network template.
    final class BatchedNetworkTemplateView {
        var code: String
        var labelText: String
        var visitMinutes: String
        var segment: String
        var locale: String
        var ratio: String
        var statusLabel: String

        init(code: String, labelText: String, visitMinutes: String, segment: String, locale: String, ratio: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.visitMinutes = visitMinutes
            self.segment = segment
            self.locale = locale
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedNetworkTemplateView(_ item: BatchedNetworkTemplate) -> BatchedNetworkTemplateView {
        return BatchedNetworkTemplateView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            visitMinutes: String(item.visitMinutes),
            segment: item.segment,
            locale: item.locale,
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedNetworkTemplateViews(_ items: [BatchedNetworkTemplate]) -> [BatchedNetworkTemplateView] {
        var views: [BatchedNetworkTemplateView] = []
        for item in items {
            views.append(toBatchedNetworkTemplateView(item))
        }
        return views
    }

    static func sumBatchedNetworkTemplateView(_ view: BatchedNetworkTemplateView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedVisitMinutes) + parsedRatio
    }
}
