import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped referral rollup.
    final class CappedReferralRollupView {
        var code: String
        var title: String
        var descriptionText: String
        var batchSize: String
        var locale: String
        var diagnosisCode: String
        var phoneText: String
        var statusLabel: String

        init(code: String, title: String, descriptionText: String, batchSize: String, locale: String, diagnosisCode: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.descriptionText = descriptionText
            self.batchSize = batchSize
            self.locale = locale
            self.diagnosisCode = diagnosisCode
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedReferralRollupView(_ item: CappedReferralRollup) -> CappedReferralRollupView {
        return CappedReferralRollupView(
            code: item.code,
            title: item.title,
            descriptionText: item.description,
            batchSize: String(item.batchSize),
            locale: item.locale,
            diagnosisCode: item.diagnosisCode,
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedReferralRollupViews(_ items: [CappedReferralRollup]) -> [CappedReferralRollupView] {
        var views: [CappedReferralRollupView] = []
        for item in items {
            views.append(toCappedReferralRollupView(item))
        }
        return views
    }

    static func sumCappedReferralRollupView(_ view: CappedReferralRollupView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
