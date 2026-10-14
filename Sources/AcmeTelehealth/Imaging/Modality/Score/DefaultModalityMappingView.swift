import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a default modality mapping.
    final class DefaultModalityMappingView {
        var code: String
        var title: String
        var version: String
        var channel: String
        var rateText: String
        var discount: String
        var statusLabel: String

        init(code: String, title: String, version: String, channel: String, rateText: String, discount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.version = version
            self.channel = channel
            self.rateText = rateText
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultModalityMappingView(_ item: DefaultModalityMapping) -> DefaultModalityMappingView {
        return DefaultModalityMappingView(
            code: item.code,
            title: item.title,
            version: String(item.version),
            channel: item.channel,
            rateText: String(format: "%.2f", item.rate),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultModalityMappingViews(_ items: [DefaultModalityMapping]) -> [DefaultModalityMappingView] {
        var views: [DefaultModalityMappingView] = []
        for item in items {
            views.append(toDefaultModalityMappingView(item))
        }
        return views
    }

    static func sumDefaultModalityMappingView(_ view: DefaultModalityMappingView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedVersion) + parsedRate + parsedDiscount
    }
}
