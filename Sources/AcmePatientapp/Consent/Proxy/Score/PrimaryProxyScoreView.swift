import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary proxy score.
    final class PrimaryProxyScoreView {
        var code: String
        var name: String
        var locale: String
        var sequence: String
        var limit: String
        var startsAt: String
        var floorValueText: String
        var acuity: String
        var labelText: String
        var statusLabel: String

        init(code: String, name: String, locale: String, sequence: String, limit: String, startsAt: String, floorValueText: String, acuity: String, labelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.locale = locale
            self.sequence = sequence
            self.limit = limit
            self.startsAt = startsAt
            self.floorValueText = floorValueText
            self.acuity = acuity
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryProxyScoreView(_ item: PrimaryProxyScore) -> PrimaryProxyScoreView {
        return PrimaryProxyScoreView(
            code: item.code,
            name: item.name,
            locale: item.locale,
            sequence: String(item.sequence),
            limit: String(item.limit),
            startsAt: String(item.startsAt),
            floorValueText: String(format: "%.2f", item.floorValue),
            acuity: String(item.acuity),
            labelText: Kit.Text.truncate(item.label, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryProxyScoreViews(_ items: [PrimaryProxyScore]) -> [PrimaryProxyScoreView] {
        var views: [PrimaryProxyScoreView] = []
        for item in items {
            views.append(toPrimaryProxyScoreView(item))
        }
        return views
    }

    static func sumPrimaryProxyScoreView(_ view: PrimaryProxyScoreView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedSequence) + Double(parsedLimit) + Double(parsedStartsAt)
    }
}
