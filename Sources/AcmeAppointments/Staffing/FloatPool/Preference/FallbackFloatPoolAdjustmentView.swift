import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback float pool adjustment.
    final class FallbackFloatPoolAdjustmentView {
        var code: String
        var label: String
        var category: String
        var expiresAtText: String
        var version: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, label: String, category: String, expiresAtText: String, version: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.category = category
            self.expiresAtText = expiresAtText
            self.version = version
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackFloatPoolAdjustmentView(_ item: FallbackFloatPoolAdjustment) -> FallbackFloatPoolAdjustmentView {
        return FallbackFloatPoolAdjustmentView(
            code: item.code,
            label: item.label,
            category: Kit.Text.truncate(item.category, limit: 40),
            expiresAtText: String(item.expiresAt),
            version: String(item.version),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackFloatPoolAdjustmentViews(_ items: [FallbackFloatPoolAdjustment]) -> [FallbackFloatPoolAdjustmentView] {
        var views: [FallbackFloatPoolAdjustmentView] = []
        for item in items {
            views.append(toFallbackFloatPoolAdjustmentView(item))
        }
        return views
    }

    static func sumFallbackFloatPoolAdjustmentView(_ view: FallbackFloatPoolAdjustmentView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedVersion)
    }
}
