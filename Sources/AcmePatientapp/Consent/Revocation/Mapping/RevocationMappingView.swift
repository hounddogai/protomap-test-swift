import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation mapping.
    final class RevocationMappingView {
        var code: String
        var name: String
        var minimumText: String
        var segmentText: String
        var category: String
        var endsAt: String
        var visible: String
        var statusLabel: String

        init(code: String, name: String, minimumText: String, segmentText: String, category: String, endsAt: String, visible: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimumText = minimumText
            self.segmentText = segmentText
            self.category = category
            self.endsAt = endsAt
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationMappingView(_ item: RevocationMapping) -> RevocationMappingView {
        return RevocationMappingView(
            code: item.code,
            name: item.name,
            minimumText: String(format: "%.2f", item.minimum),
            segmentText: item.segment,
            category: Kit.Text.truncate(item.category, limit: 120),
            endsAt: String(item.endsAt),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationMappingViews(_ items: [RevocationMapping]) -> [RevocationMappingView] {
        var views: [RevocationMappingView] = []
        for item in items {
            views.append(toRevocationMappingView(item))
        }
        return views
    }

    static func sumRevocationMappingView(_ view: RevocationMappingView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMinimum + Double(parsedEndsAt)
    }
}
