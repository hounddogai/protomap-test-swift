import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap exception.
    final class CareGapExceptionView {
        var code: String
        var title: String
        var description: String
        var allergy: String
        var startsAtText: String
        var version: String
        var phone: String
        var diagnosisCodeText: String
        var source: String
        var cost: String
        var statusLabel: String

        init(code: String, title: String, description: String, allergy: String, startsAtText: String, version: String, phone: String, diagnosisCodeText: String, source: String, cost: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.allergy = allergy
            self.startsAtText = startsAtText
            self.version = version
            self.phone = phone
            self.diagnosisCodeText = diagnosisCodeText
            self.source = source
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapExceptionView(_ item: CareGapException) -> CareGapExceptionView {
        return CareGapExceptionView(
            code: item.code,
            title: item.title,
            description: item.description,
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            startsAtText: String(item.startsAt),
            version: String(item.version),
            phone: item.phone,
            diagnosisCodeText: item.diagnosisCode,
            source: Kit.Text.truncate(item.source, limit: 40),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapExceptionViews(_ items: [CareGapException]) -> [CareGapExceptionView] {
        var views: [CareGapExceptionView] = []
        for item in items {
            views.append(toCareGapExceptionView(item))
        }
        return views
    }

    static func sumCareGapExceptionView(_ view: CareGapExceptionView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedVersion) + parsedCost
    }
}
