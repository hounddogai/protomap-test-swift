import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered care gap digest.
    final class TieredCareGapDigestView {
        var codeText: String
        var name: String
        var archived: String
        var payerText: String
        var acuityText: String
        var summary: String
        var specialty: String
        var unit: String
        var graceDays: String
        var limit: String
        var endsAtText: String
        var statusLabel: String

        init(codeText: String, name: String, archived: String, payerText: String, acuityText: String, summary: String, specialty: String, unit: String, graceDays: String, limit: String, endsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.archived = archived
            self.payerText = payerText
            self.acuityText = acuityText
            self.summary = summary
            self.specialty = specialty
            self.unit = unit
            self.graceDays = graceDays
            self.limit = limit
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCareGapDigestView(_ item: TieredCareGapDigest) -> TieredCareGapDigestView {
        return TieredCareGapDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            archived: "\(item.archived)",
            payerText: Kit.Text.truncate(item.payer, limit: 120),
            acuityText: String(item.acuity),
            summary: item.summary,
            specialty: item.specialty,
            unit: item.unit,
            graceDays: String(item.graceDays),
            limit: String(item.limit),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCareGapDigestViews(_ items: [TieredCareGapDigest]) -> [TieredCareGapDigestView] {
        var views: [TieredCareGapDigestView] = []
        for item in items {
            views.append(toTieredCareGapDigestView(item))
        }
        return views
    }

    static func sumTieredCareGapDigestView(_ view: TieredCareGapDigestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedAcuity) + Double(parsedGraceDays) + Double(parsedLimit)
    }
}
