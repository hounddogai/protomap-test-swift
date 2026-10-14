import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback inventory target.
    final class FallbackInventoryTargetView {
        var codeText: String
        var nameText: String
        var source: String
        var capacity: String
        var ratioText: String
        var statusLabel: String

        init(codeText: String, nameText: String, source: String, capacity: String, ratioText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.source = source
            self.capacity = capacity
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackInventoryTargetView(_ item: FallbackInventoryTarget) -> FallbackInventoryTargetView {
        return FallbackInventoryTargetView(
            codeText: item.code,
            nameText: item.name,
            source: Kit.Text.truncate(item.source, limit: 80),
            capacity: String(item.capacity),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackInventoryTargetViews(_ items: [FallbackInventoryTarget]) -> [FallbackInventoryTargetView] {
        var views: [FallbackInventoryTargetView] = []
        for item in items {
            views.append(toFallbackInventoryTargetView(item))
        }
        return views
    }

    static func sumFallbackInventoryTargetView(_ view: FallbackInventoryTargetView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedCapacity) + parsedRatio
    }
}
