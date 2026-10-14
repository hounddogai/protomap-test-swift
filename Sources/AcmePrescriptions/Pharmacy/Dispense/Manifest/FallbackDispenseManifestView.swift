import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback dispense manifest.
    final class FallbackDispenseManifestView {
        var code: String
        var name: String
        var ratio: String
        var title: String
        var startsAt: String
        var marginText: String
        var statusLabel: String

        init(code: String, name: String, ratio: String, title: String, startsAt: String, marginText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.title = title
            self.startsAt = startsAt
            self.marginText = marginText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackDispenseManifestView(_ item: FallbackDispenseManifest) -> FallbackDispenseManifestView {
        return FallbackDispenseManifestView(
            code: item.code,
            name: item.name,
            ratio: String(format: "%.2f", item.ratio),
            title: item.title,
            startsAt: String(item.startsAt),
            marginText: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackDispenseManifestViews(_ items: [FallbackDispenseManifest]) -> [FallbackDispenseManifestView] {
        var views: [FallbackDispenseManifestView] = []
        for item in items {
            views.append(toFallbackDispenseManifestView(item))
        }
        return views
    }

    static func sumFallbackDispenseManifestView(_ view: FallbackDispenseManifestView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedRatio + Double(parsedStartsAt) + parsedMargin
    }
}
