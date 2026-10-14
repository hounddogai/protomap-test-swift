import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen segment.
    final class SpecimenSegmentView {
        var code: String
        var name: String
        var expiresAtText: String
        var startsAtText: String
        var currencyText: String
        var createdAt: String
        var weightText: String
        var minimum: String
        var statusLabel: String

        init(code: String, name: String, expiresAtText: String, startsAtText: String, currencyText: String, createdAt: String, weightText: String, minimum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAtText = expiresAtText
            self.startsAtText = startsAtText
            self.currencyText = currencyText
            self.createdAt = createdAt
            self.weightText = weightText
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenSegmentView(_ item: SpecimenSegment) -> SpecimenSegmentView {
        return SpecimenSegmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            expiresAtText: String(item.expiresAt),
            startsAtText: String(item.startsAt),
            currencyText: item.currency,
            createdAt: String(item.createdAt),
            weightText: String(format: "%.2f", item.weight),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenSegmentViews(_ items: [SpecimenSegment]) -> [SpecimenSegmentView] {
        var views: [SpecimenSegmentView] = []
        for item in items {
            views.append(toSpecimenSegmentView(item))
        }
        return views
    }

    static func sumSpecimenSegmentView(_ view: SpecimenSegmentView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedStartsAt) + Double(parsedCreatedAt)
    }
}
