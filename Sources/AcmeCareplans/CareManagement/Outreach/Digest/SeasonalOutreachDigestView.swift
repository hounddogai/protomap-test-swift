import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal outreach digest.
    final class SeasonalOutreachDigestView {
        var code: String
        var name: String
        var windowDays: String
        var createdAtText: String
        var marginText: String
        var acuity: String
        var labelText: String
        var capacity: String
        var priority: String
        var bedText: String
        var statusLabel: String

        init(code: String, name: String, windowDays: String, createdAtText: String, marginText: String, acuity: String, labelText: String, capacity: String, priority: String, bedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.createdAtText = createdAtText
            self.marginText = marginText
            self.acuity = acuity
            self.labelText = labelText
            self.capacity = capacity
            self.priority = priority
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalOutreachDigestView(_ item: SeasonalOutreachDigest) -> SeasonalOutreachDigestView {
        return SeasonalOutreachDigestView(
            code: item.code,
            name: item.name,
            windowDays: String(item.windowDays),
            createdAtText: String(item.createdAt),
            marginText: String(format: "%.2f", item.margin),
            acuity: String(item.acuity),
            labelText: item.label,
            capacity: String(item.capacity),
            priority: String(item.priority),
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalOutreachDigestViews(_ items: [SeasonalOutreachDigest]) -> [SeasonalOutreachDigestView] {
        var views: [SeasonalOutreachDigestView] = []
        for item in items {
            views.append(toSeasonalOutreachDigestView(item))
        }
        return views
    }

    static func sumSeasonalOutreachDigestView(_ view: SeasonalOutreachDigestView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedCreatedAt) + parsedMargin
    }
}
