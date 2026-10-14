import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language window.
    final class LanguageWindowView {
        var code: String
        var label: String
        var encounterID: String
        var ratio: String
        var limit: String
        var rate: String
        var patientRef: String
        var name: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, ratio: String, limit: String, rate: String, patientRef: String, name: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.ratio = ratio
            self.limit = limit
            self.rate = rate
            self.patientRef = patientRef
            self.name = name
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageWindowView(_ item: LanguageWindow) -> LanguageWindowView {
        return LanguageWindowView(
            code: item.code,
            label: item.label,
            encounterID: item.encounterID,
            ratio: String(format: "%.2f", item.ratio),
            limit: String(item.limit),
            rate: String(format: "%.2f", item.rate),
            patientRef: item.patientRef,
            name: item.name,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageWindowViews(_ items: [LanguageWindow]) -> [LanguageWindowView] {
        var views: [LanguageWindowView] = []
        for item in items {
            views.append(toLanguageWindowView(item))
        }
        return views
    }

    static func sumLanguageWindowView(_ view: LanguageWindowView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRatio + Double(parsedLimit) + parsedRate
    }
}
