import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census profile.
    final class CensusProfileView {
        var code: String
        var titleText: String
        var batchSize: String
        var ward: String
        var copayText: String
        var endsAt: String
        var clinicianID: String
        var limit: String
        var specialtyText: String
        var ratio: String
        var acuity: String
        var statusLabel: String

        init(code: String, titleText: String, batchSize: String, ward: String, copayText: String, endsAt: String, clinicianID: String, limit: String, specialtyText: String, ratio: String, acuity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.batchSize = batchSize
            self.ward = ward
            self.copayText = copayText
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.limit = limit
            self.specialtyText = specialtyText
            self.ratio = ratio
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toCensusProfileView(_ item: CensusProfile) -> CensusProfileView {
        return CensusProfileView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            batchSize: String(item.batchSize),
            ward: item.ward,
            copayText: String(format: "%.2f", item.copay),
            endsAt: String(item.endsAt),
            clinicianID: item.clinicianID,
            limit: String(item.limit),
            specialtyText: item.specialty,
            ratio: String(format: "%.2f", item.ratio),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusProfileViews(_ items: [CensusProfile]) -> [CensusProfileView] {
        var views: [CensusProfileView] = []
        for item in items {
            views.append(toCensusProfileView(item))
        }
        return views
    }

    static func sumCensusProfileView(_ view: CensusProfileView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedBatchSize) + parsedCopay + Double(parsedEndsAt)
    }
}
