import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped inventory preference.
    final class CappedInventoryPreferenceView {
        var codeText: String
        var name: String
        var clinicianIDText: String
        var procedureCode: String
        var thresholdText: String
        var phone: String
        var graceDaysText: String
        var statusLabel: String

        init(codeText: String, name: String, clinicianIDText: String, procedureCode: String, thresholdText: String, phone: String, graceDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.clinicianIDText = clinicianIDText
            self.procedureCode = procedureCode
            self.thresholdText = thresholdText
            self.phone = phone
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedInventoryPreferenceView(_ item: CappedInventoryPreference) -> CappedInventoryPreferenceView {
        return CappedInventoryPreferenceView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            clinicianIDText: item.clinicianID,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            thresholdText: String(format: "%.2f", item.threshold),
            phone: item.phone,
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedInventoryPreferenceViews(_ items: [CappedInventoryPreference]) -> [CappedInventoryPreferenceView] {
        var views: [CappedInventoryPreferenceView] = []
        for item in items {
            views.append(toCappedInventoryPreferenceView(item))
        }
        return views
    }

    static func sumCappedInventoryPreferenceView(_ view: CappedInventoryPreferenceView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedThreshold + Double(parsedGraceDays)
    }
}
