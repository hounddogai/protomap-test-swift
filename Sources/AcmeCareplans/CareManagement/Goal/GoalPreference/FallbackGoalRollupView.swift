import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback goal rollup.
    final class FallbackGoalRollupView {
        var code: String
        var name: String
        var externalRef: String
        var phone: String
        var channel: String
        var copay: String
        var visible: String
        var margin: String
        var approvedText: String
        var expiresAtText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, externalRef: String, phone: String, channel: String, copay: String, visible: String, margin: String, approvedText: String, expiresAtText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.phone = phone
            self.channel = channel
            self.copay = copay
            self.visible = visible
            self.margin = margin
            self.approvedText = approvedText
            self.expiresAtText = expiresAtText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackGoalRollupView(_ item: FallbackGoalRollup) -> FallbackGoalRollupView {
        return FallbackGoalRollupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            externalRef: item.externalRef,
            phone: item.phone,
            channel: Kit.Text.truncate(item.channel, limit: 64),
            copay: String(format: "%.2f", item.copay),
            visible: "\(item.visible)",
            margin: String(format: "%.2f", item.margin),
            approvedText: "\(item.approved)",
            expiresAtText: String(item.expiresAt),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackGoalRollupViews(_ items: [FallbackGoalRollup]) -> [FallbackGoalRollupView] {
        var views: [FallbackGoalRollupView] = []
        for item in items {
            views.append(toFallbackGoalRollupView(item))
        }
        return views
    }

    static func sumFallbackGoalRollupView(_ view: FallbackGoalRollupView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedCopay + parsedMargin + Double(parsedExpiresAt)
    }
}
