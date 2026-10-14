import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol variance.
    final class CareProtocolVarianceView {
        var codeText: String
        var title: String
        var ratioText: String
        var notes: String
        var ceiling: String
        var currency: String
        var procedureCode: String
        var margin: String
        var scoreText: String
        var archivedText: String
        var ward: String
        var statusLabel: String

        init(codeText: String, title: String, ratioText: String, notes: String, ceiling: String, currency: String, procedureCode: String, margin: String, scoreText: String, archivedText: String, ward: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ratioText = ratioText
            self.notes = notes
            self.ceiling = ceiling
            self.currency = currency
            self.procedureCode = procedureCode
            self.margin = margin
            self.scoreText = scoreText
            self.archivedText = archivedText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolVarianceView(_ item: CareProtocolVariance) -> CareProtocolVarianceView {
        return CareProtocolVarianceView(
            codeText: item.code,
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            notes: Kit.Text.truncate(item.notes, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            currency: item.currency,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            margin: String(format: "%.2f", item.margin),
            scoreText: String(format: "%.2f", item.score),
            archivedText: "\(item.archived)",
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolVarianceViews(_ items: [CareProtocolVariance]) -> [CareProtocolVarianceView] {
        var views: [CareProtocolVarianceView] = []
        for item in items {
            views.append(toCareProtocolVarianceView(item))
        }
        return views
    }

    static func sumCareProtocolVarianceView(_ view: CareProtocolVarianceView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedRatio + parsedCeiling + parsedMargin
    }
}
