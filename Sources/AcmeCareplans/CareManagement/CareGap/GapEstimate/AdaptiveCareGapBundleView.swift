import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive care gap bundle.
    final class AdaptiveCareGapBundleView {
        var codeText: String
        var labelText: String
        var notes: String
        var graceDays: String
        var active: String
        var limit: String
        var category: String
        var expiresAt: String
        var updatedAt: String
        var statusLabel: String

        init(codeText: String, labelText: String, notes: String, graceDays: String, active: String, limit: String, category: String, expiresAt: String, updatedAt: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.notes = notes
            self.graceDays = graceDays
            self.active = active
            self.limit = limit
            self.category = category
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCareGapBundleView(_ item: AdaptiveCareGapBundle) -> AdaptiveCareGapBundleView {
        return AdaptiveCareGapBundleView(
            codeText: item.code,
            labelText: item.label,
            notes: Kit.Text.truncate(item.notes, limit: 80),
            graceDays: String(item.graceDays),
            active: "\(item.active)",
            limit: String(item.limit),
            category: item.category,
            expiresAt: String(item.expiresAt),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCareGapBundleViews(_ items: [AdaptiveCareGapBundle]) -> [AdaptiveCareGapBundleView] {
        var views: [AdaptiveCareGapBundleView] = []
        for item in items {
            views.append(toAdaptiveCareGapBundleView(item))
        }
        return views
    }

    static func sumAdaptiveCareGapBundleView(_ view: AdaptiveCareGapBundleView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedLimit) + Double(parsedExpiresAt)
    }
}
