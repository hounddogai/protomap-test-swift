import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a lenient proxy template.
    final class LenientProxyTemplateView {
        var codeText: String
        var name: String
        var refillsText: String
        var countryText: String
        var wardText: String
        var statusLabel: String

        init(codeText: String, name: String, refillsText: String, countryText: String, wardText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.refillsText = refillsText
            self.countryText = countryText
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientProxyTemplateView(_ item: LenientProxyTemplate) -> LenientProxyTemplateView {
        return LenientProxyTemplateView(
            codeText: item.code,
            name: item.name,
            refillsText: String(item.refills),
            countryText: item.country,
            wardText: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientProxyTemplateViews(_ items: [LenientProxyTemplate]) -> [LenientProxyTemplateView] {
        var views: [LenientProxyTemplateView] = []
        for item in items {
            views.append(toLenientProxyTemplateView(item))
        }
        return views
    }

    static func sumLenientProxyTemplateView(_ view: LenientProxyTemplateView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
