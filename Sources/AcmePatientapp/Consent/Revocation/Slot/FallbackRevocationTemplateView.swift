import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback revocation template.
    final class FallbackRevocationTemplateView {
        var code: String
        var titleText: String
        var ceiling: String
        var retriesText: String
        var phone: String
        var statusLabel: String

        init(code: String, titleText: String, ceiling: String, retriesText: String, phone: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ceiling = ceiling
            self.retriesText = retriesText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackRevocationTemplateView(_ item: FallbackRevocationTemplate) -> FallbackRevocationTemplateView {
        return FallbackRevocationTemplateView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            retriesText: String(item.retries),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackRevocationTemplateViews(_ items: [FallbackRevocationTemplate]) -> [FallbackRevocationTemplateView] {
        var views: [FallbackRevocationTemplateView] = []
        for item in items {
            views.append(toFallbackRevocationTemplateView(item))
        }
        return views
    }

    static func sumFallbackRevocationTemplateView(_ view: FallbackRevocationTemplateView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedCeiling + Double(parsedRetries)
    }
}
