import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result override.
    final class ResultOverrideView {
        var code: String
        var label: String
        var ceiling: String
        var externalRef: String
        var expiresAt: String
        var endsAt: String
        var createdAtText: String
        var acuityText: String
        var marginText: String
        var durationMinutes: String
        var bed: String
        var statusLabel: String

        init(code: String, label: String, ceiling: String, externalRef: String, expiresAt: String, endsAt: String, createdAtText: String, acuityText: String, marginText: String, durationMinutes: String, bed: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.endsAt = endsAt
            self.createdAtText = createdAtText
            self.acuityText = acuityText
            self.marginText = marginText
            self.durationMinutes = durationMinutes
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toResultOverrideView(_ item: ResultOverride) -> ResultOverrideView {
        return ResultOverrideView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            externalRef: item.externalRef,
            expiresAt: String(item.expiresAt),
            endsAt: String(item.endsAt),
            createdAtText: String(item.createdAt),
            acuityText: String(item.acuity),
            marginText: String(format: "%.2f", item.margin),
            durationMinutes: String(item.durationMinutes),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultOverrideViews(_ items: [ResultOverride]) -> [ResultOverrideView] {
        var views: [ResultOverrideView] = []
        for item in items {
            views.append(toResultOverrideView(item))
        }
        return views
    }

    static func sumResultOverrideView(_ view: ResultOverrideView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedCeiling + Double(parsedExpiresAt) + Double(parsedEndsAt)
    }
}
