import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling census checkpoint.
    final class RollingCensusCheckpointView {
        var code: String
        var label: String
        var locale: String
        var retries: String
        var pinnedText: String
        var regionText: String
        var margin: String
        var active: String
        var expiresAt: String
        var endsAt: String
        var statusLabel: String

        init(code: String, label: String, locale: String, retries: String, pinnedText: String, regionText: String, margin: String, active: String, expiresAt: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.locale = locale
            self.retries = retries
            self.pinnedText = pinnedText
            self.regionText = regionText
            self.margin = margin
            self.active = active
            self.expiresAt = expiresAt
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCensusCheckpointView(_ item: RollingCensusCheckpoint) -> RollingCensusCheckpointView {
        return RollingCensusCheckpointView(
            code: item.code,
            label: item.label,
            locale: Kit.Text.truncate(item.locale, limit: 64),
            retries: String(item.retries),
            pinnedText: "\(item.pinned)",
            regionText: item.region,
            margin: String(format: "%.2f", item.margin),
            active: "\(item.active)",
            expiresAt: String(item.expiresAt),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCensusCheckpointViews(_ items: [RollingCensusCheckpoint]) -> [RollingCensusCheckpointView] {
        var views: [RollingCensusCheckpointView] = []
        for item in items {
            views.append(toRollingCensusCheckpointView(item))
        }
        return views
    }

    static func sumRollingCensusCheckpointView(_ view: RollingCensusCheckpointView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRetries) + parsedMargin + Double(parsedExpiresAt)
    }
}
