import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form batch.
    final class ConsentFormBatchView {
        var code: String
        var nameText: String
        var description: String
        var refills: String
        var country: String
        var weight: String
        var encounterIDText: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, nameText: String, description: String, refills: String, country: String, weight: String, encounterIDText: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.description = description
            self.refills = refills
            self.country = country
            self.weight = weight
            self.encounterIDText = encounterIDText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormBatchView(_ item: ConsentFormBatch) -> ConsentFormBatchView {
        return ConsentFormBatchView(
            code: item.code,
            nameText: item.name,
            description: item.description,
            refills: String(item.refills),
            country: item.country,
            weight: String(format: "%.2f", item.weight),
            encounterIDText: item.encounterID,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormBatchViews(_ items: [ConsentFormBatch]) -> [ConsentFormBatchView] {
        var views: [ConsentFormBatchView] = []
        for item in items {
            views.append(toConsentFormBatchView(item))
        }
        return views
    }

    static func sumConsentFormBatchView(_ view: ConsentFormBatchView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedRefills) + parsedWeight + parsedDosageMg
    }
}
