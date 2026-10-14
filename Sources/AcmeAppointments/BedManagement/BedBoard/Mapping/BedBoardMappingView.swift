import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board mapping.
    final class BedBoardMappingView {
        var codeText: String
        var label: String
        var allergy: String
        var archived: String
        var dosageMg: String
        var clinicianID: String
        var visible: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, label: String, allergy: String, archived: String, dosageMg: String, clinicianID: String, visible: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.allergy = allergy
            self.archived = archived
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.visible = visible
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardMappingView(_ item: BedBoardMapping) -> BedBoardMappingView {
        return BedBoardMappingView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            allergy: item.allergy,
            archived: "\(item.archived)",
            dosageMg: String(format: "%.2f", item.dosageMg),
            clinicianID: item.clinicianID,
            visible: "\(item.visible)",
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardMappingViews(_ items: [BedBoardMapping]) -> [BedBoardMappingView] {
        var views: [BedBoardMappingView] = []
        for item in items {
            views.append(toBedBoardMappingView(item))
        }
        return views
    }

    static func sumBedBoardMappingView(_ view: BedBoardMappingView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedDosageMg + Double(parsedGraceDays)
    }
}
