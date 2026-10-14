import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a tiered recall summary.
    final class TieredRecallSummaryView {
        var codeText: String
        var label: String
        var diagnosisCode: String
        var checksumText: String
        var patientRef: String
        var country: String
        var phone: String
        var amount: String
        var statusLabel: String

        init(codeText: String, label: String, diagnosisCode: String, checksumText: String, patientRef: String, country: String, phone: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.checksumText = checksumText
            self.patientRef = patientRef
            self.country = country
            self.phone = phone
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRecallSummaryView(_ item: TieredRecallSummary) -> TieredRecallSummaryView {
        return TieredRecallSummaryView(
            codeText: item.code,
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            checksumText: item.checksum,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            country: Kit.Text.truncate(item.country, limit: 40),
            phone: item.phone,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRecallSummaryViews(_ items: [TieredRecallSummary]) -> [TieredRecallSummaryView] {
        var views: [TieredRecallSummaryView] = []
        for item in items {
            views.append(toTieredRecallSummaryView(item))
        }
        return views
    }

    static func sumTieredRecallSummaryView(_ view: TieredRecallSummaryView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
