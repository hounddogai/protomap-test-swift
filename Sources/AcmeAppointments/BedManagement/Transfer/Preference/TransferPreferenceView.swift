import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer preference.
    final class TransferPreferenceView {
        var codeText: String
        var title: String
        var unit: String
        var facilityText: String
        var ownerID: String
        var bed: String
        var margin: String
        var diagnosisCodeText: String
        var category: String
        var statusLabel: String

        init(codeText: String, title: String, unit: String, facilityText: String, ownerID: String, bed: String, margin: String, diagnosisCodeText: String, category: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.unit = unit
            self.facilityText = facilityText
            self.ownerID = ownerID
            self.bed = bed
            self.margin = margin
            self.diagnosisCodeText = diagnosisCodeText
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toTransferPreferenceView(_ item: TransferPreference) -> TransferPreferenceView {
        return TransferPreferenceView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            unit: Kit.Text.truncate(item.unit, limit: 80),
            facilityText: item.facility,
            ownerID: item.ownerID,
            bed: item.bed,
            margin: String(format: "%.2f", item.margin),
            diagnosisCodeText: item.diagnosisCode,
            category: Kit.Text.truncate(item.category, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferPreferenceViews(_ items: [TransferPreference]) -> [TransferPreferenceView] {
        var views: [TransferPreferenceView] = []
        for item in items {
            views.append(toTransferPreferenceView(item))
        }
        return views
    }

    static func sumTransferPreferenceView(_ view: TransferPreferenceView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
