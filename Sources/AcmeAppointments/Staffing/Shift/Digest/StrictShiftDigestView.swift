import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict shift digest.
    final class StrictShiftDigestView {
        var code: String
        var titleText: String
        var allergy: String
        var payer: String
        var diagnosisCode: String
        var limit: String
        var currencyText: String
        var statusLabel: String

        init(code: String, titleText: String, allergy: String, payer: String, diagnosisCode: String, limit: String, currencyText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.allergy = allergy
            self.payer = payer
            self.diagnosisCode = diagnosisCode
            self.limit = limit
            self.currencyText = currencyText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictShiftDigestView(_ item: StrictShiftDigest) -> StrictShiftDigestView {
        return StrictShiftDigestView(
            code: item.code,
            titleText: item.title,
            allergy: item.allergy,
            payer: item.payer,
            diagnosisCode: item.diagnosisCode,
            limit: String(item.limit),
            currencyText: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictShiftDigestViews(_ items: [StrictShiftDigest]) -> [StrictShiftDigestView] {
        var views: [StrictShiftDigestView] = []
        for item in items {
            views.append(toStrictShiftDigestView(item))
        }
        return views
    }

    static func sumStrictShiftDigestView(_ view: StrictShiftDigestView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
