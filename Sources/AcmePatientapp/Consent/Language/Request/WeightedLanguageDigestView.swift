import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a weighted language digest.
    final class WeightedLanguageDigestView {
        var code: String
        var nameText: String
        var allergyText: String
        var facilityText: String
        var payer: String
        var batchSize: String
        var procedureCode: String
        var encounterIDText: String
        var refills: String
        var timezone: String
        var ratio: String
        var statusLabel: String

        init(code: String, nameText: String, allergyText: String, facilityText: String, payer: String, batchSize: String, procedureCode: String, encounterIDText: String, refills: String, timezone: String, ratio: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.allergyText = allergyText
            self.facilityText = facilityText
            self.payer = payer
            self.batchSize = batchSize
            self.procedureCode = procedureCode
            self.encounterIDText = encounterIDText
            self.refills = refills
            self.timezone = timezone
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedLanguageDigestView(_ item: WeightedLanguageDigest) -> WeightedLanguageDigestView {
        return WeightedLanguageDigestView(
            code: item.code,
            nameText: item.name,
            allergyText: item.allergy,
            facilityText: item.facility,
            payer: Kit.Text.truncate(item.payer, limit: 64),
            batchSize: String(item.batchSize),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            encounterIDText: item.encounterID,
            refills: String(item.refills),
            timezone: item.timezone,
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedLanguageDigestViews(_ items: [WeightedLanguageDigest]) -> [WeightedLanguageDigestView] {
        var views: [WeightedLanguageDigestView] = []
        for item in items {
            views.append(toWeightedLanguageDigestView(item))
        }
        return views
    }

    static func sumWeightedLanguageDigestView(_ view: WeightedLanguageDigestView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedRefills) + parsedRatio
    }
}
