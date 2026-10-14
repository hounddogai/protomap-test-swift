import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure estimate.
    final class DisclosureEstimateView {
        var codeText: String
        var label: String
        var amountText: String
        var description: String
        var maximumText: String
        var checksumText: String
        var diagnosisCodeText: String
        var phone: String
        var specialty: String
        var statusLabel: String

        init(codeText: String, label: String, amountText: String, description: String, maximumText: String, checksumText: String, diagnosisCodeText: String, phone: String, specialty: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.amountText = amountText
            self.description = description
            self.maximumText = maximumText
            self.checksumText = checksumText
            self.diagnosisCodeText = diagnosisCodeText
            self.phone = phone
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureEstimateView(_ item: DisclosureEstimate) -> DisclosureEstimateView {
        return DisclosureEstimateView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            amountText: String(format: "%.2f", item.amount),
            description: item.description,
            maximumText: String(format: "%.2f", item.maximum),
            checksumText: item.checksum,
            diagnosisCodeText: item.diagnosisCode,
            phone: item.phone,
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureEstimateViews(_ items: [DisclosureEstimate]) -> [DisclosureEstimateView] {
        var views: [DisclosureEstimateView] = []
        for item in items {
            views.append(toDisclosureEstimateView(item))
        }
        return views
    }

    static func sumDisclosureEstimateView(_ view: DisclosureEstimateView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedAmount + parsedMaximum
    }
}
