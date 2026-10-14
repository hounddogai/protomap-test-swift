import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default result manifest.
    final class DefaultResultManifestView {
        var codeText: String
        var labelText: String
        var summary: String
        var endsAtText: String
        var minimum: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, labelText: String, summary: String, endsAtText: String, minimum: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.summary = summary
            self.endsAtText = endsAtText
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultResultManifestView(_ item: DefaultResultManifest) -> DefaultResultManifestView {
        return DefaultResultManifestView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            summary: item.summary,
            endsAtText: String(item.endsAt),
            minimum: String(format: "%.2f", item.minimum),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultResultManifestViews(_ items: [DefaultResultManifest]) -> [DefaultResultManifestView] {
        var views: [DefaultResultManifestView] = []
        for item in items {
            views.append(toDefaultResultManifestView(item))
        }
        return views
    }

    static func sumDefaultResultManifestView(_ view: DefaultResultManifestView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedEndsAt) + parsedMinimum + Double(parsedDurationMinutes)
    }
}
