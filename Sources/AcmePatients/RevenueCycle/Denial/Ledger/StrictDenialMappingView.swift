import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a strict denial mapping.
    final class StrictDenialMappingView {
        var codeText: String
        var nameText: String
        var summary: String
        var discount: String
        var version: String
        var statusLabel: String

        init(codeText: String, nameText: String, summary: String, discount: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.summary = summary
            self.discount = discount
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toStrictDenialMappingView(_ item: StrictDenialMapping) -> StrictDenialMappingView {
        return StrictDenialMappingView(
            codeText: item.code,
            nameText: item.name,
            summary: item.summary,
            discount: String(format: "%.2f", item.discount),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictDenialMappingViews(_ items: [StrictDenialMapping]) -> [StrictDenialMappingView] {
        var views: [StrictDenialMappingView] = []
        for item in items {
            views.append(toStrictDenialMappingView(item))
        }
        return views
    }

    static func sumStrictDenialMappingView(_ view: StrictDenialMappingView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedDiscount + Double(parsedVersion)
    }
}
