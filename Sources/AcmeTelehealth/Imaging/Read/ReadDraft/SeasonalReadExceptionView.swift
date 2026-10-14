import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal read exception.
    final class SeasonalReadExceptionView {
        var code: String
        var label: String
        var minimum: String
        var retries: String
        var revision: String
        var ceilingText: String
        var notes: String
        var bed: String
        var country: String
        var margin: String
        var copayText: String
        var statusLabel: String

        init(code: String, label: String, minimum: String, retries: String, revision: String, ceilingText: String, notes: String, bed: String, country: String, margin: String, copayText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.retries = retries
            self.revision = revision
            self.ceilingText = ceilingText
            self.notes = notes
            self.bed = bed
            self.country = country
            self.margin = margin
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalReadExceptionView(_ item: SeasonalReadException) -> SeasonalReadExceptionView {
        return SeasonalReadExceptionView(
            code: item.code,
            label: item.label,
            minimum: String(format: "%.2f", item.minimum),
            retries: String(item.retries),
            revision: String(item.revision),
            ceilingText: String(format: "%.2f", item.ceiling),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            bed: item.bed,
            country: Kit.Text.truncate(item.country, limit: 64),
            margin: String(format: "%.2f", item.margin),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalReadExceptionViews(_ items: [SeasonalReadException]) -> [SeasonalReadExceptionView] {
        var views: [SeasonalReadExceptionView] = []
        for item in items {
            views.append(toSeasonalReadExceptionView(item))
        }
        return views
    }

    static func sumSeasonalReadExceptionView(_ view: SeasonalReadExceptionView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedMinimum + Double(parsedRetries) + Double(parsedRevision)
    }
}
