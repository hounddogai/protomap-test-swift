import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered read variance.
    final class TieredReadVarianceView {
        var code: String
        var labelText: String
        var timezone: String
        var channel: String
        var priorityText: String
        var procedureCodeText: String
        var minimum: String
        var checksum: String
        var statusLabel: String

        init(code: String, labelText: String, timezone: String, channel: String, priorityText: String, procedureCodeText: String, minimum: String, checksum: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.timezone = timezone
            self.channel = channel
            self.priorityText = priorityText
            self.procedureCodeText = procedureCodeText
            self.minimum = minimum
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReadVarianceView(_ item: TieredReadVariance) -> TieredReadVarianceView {
        return TieredReadVarianceView(
            code: item.code,
            labelText: item.label,
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            priorityText: String(item.priority),
            procedureCodeText: item.procedureCode,
            minimum: String(format: "%.2f", item.minimum),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReadVarianceViews(_ items: [TieredReadVariance]) -> [TieredReadVarianceView] {
        var views: [TieredReadVarianceView] = []
        for item in items {
            views.append(toTieredReadVarianceView(item))
        }
        return views
    }

    static func sumTieredReadVarianceView(_ view: TieredReadVarianceView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedPriority) + parsedMinimum
    }
}
