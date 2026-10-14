import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive priority override.
    final class AdaptivePriorityOverrideView {
        var code: String
        var label: String
        var approved: String
        var pinned: String
        var expiresAt: String
        var source: String
        var ratio: String
        var visibleText: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, label: String, approved: String, pinned: String, expiresAt: String, source: String, ratio: String, visibleText: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.approved = approved
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.source = source
            self.ratio = ratio
            self.visibleText = visibleText
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptivePriorityOverrideView(_ item: AdaptivePriorityOverride) -> AdaptivePriorityOverrideView {
        return AdaptivePriorityOverrideView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            approved: "\(item.approved)",
            pinned: "\(item.pinned)",
            expiresAt: String(item.expiresAt),
            source: item.source,
            ratio: String(format: "%.2f", item.ratio),
            visibleText: "\(item.visible)",
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptivePriorityOverrideViews(_ items: [AdaptivePriorityOverride]) -> [AdaptivePriorityOverrideView] {
        var views: [AdaptivePriorityOverrideView] = []
        for item in items {
            views.append(toAdaptivePriorityOverrideView(item))
        }
        return views
    }

    static func sumAdaptivePriorityOverrideView(_ view: AdaptivePriorityOverrideView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedExpiresAt) + parsedRatio
    }
}
