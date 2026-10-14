import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure mapping.
    final class DisclosureMappingView {
        var codeText: String
        var title: String
        var source: String
        var segment: String
        var pinnedText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, title: String, source: String, segment: String, pinnedText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.source = source
            self.segment = segment
            self.pinnedText = pinnedText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureMappingView(_ item: DisclosureMapping) -> DisclosureMappingView {
        return DisclosureMappingView(
            codeText: item.code,
            title: item.title,
            source: Kit.Text.truncate(item.source, limit: 120),
            segment: item.segment,
            pinnedText: "\(item.pinned)",
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureMappingViews(_ items: [DisclosureMapping]) -> [DisclosureMappingView] {
        var views: [DisclosureMappingView] = []
        for item in items {
            views.append(toDisclosureMappingView(item))
        }
        return views
    }

    static func sumDisclosureMappingView(_ view: DisclosureMappingView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
