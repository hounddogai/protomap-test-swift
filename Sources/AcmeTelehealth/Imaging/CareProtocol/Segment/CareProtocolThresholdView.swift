import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol threshold.
    final class CareProtocolThresholdView {
        var codeText: String
        var name: String
        var patientRef: String
        var country: String
        var phoneText: String
        var dosageMgText: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, name: String, patientRef: String, country: String, phoneText: String, dosageMgText: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.patientRef = patientRef
            self.country = country
            self.phoneText = phoneText
            self.dosageMgText = dosageMgText
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolThresholdView(_ item: CareProtocolThreshold) -> CareProtocolThresholdView {
        return CareProtocolThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            patientRef: item.patientRef,
            country: item.country,
            phoneText: Kit.Text.truncate(item.phone, limit: 120),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolThresholdViews(_ items: [CareProtocolThreshold]) -> [CareProtocolThresholdView] {
        var views: [CareProtocolThresholdView] = []
        for item in items {
            views.append(toCareProtocolThresholdView(item))
        }
        return views
    }

    static func sumCareProtocolThresholdView(_ view: CareProtocolThresholdView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedDosageMg + parsedCeiling
    }
}
