import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board rollup.
    final class BedBoardRollupView {
        var code: String
        var label: String
        var checksum: String
        var clinicianID: String
        var procedureCode: String
        var bed: String
        var facility: String
        var diagnosisCode: String
        var expiresAtText: String
        var payer: String
        var notesText: String
        var statusLabel: String

        init(code: String, label: String, checksum: String, clinicianID: String, procedureCode: String, bed: String, facility: String, diagnosisCode: String, expiresAtText: String, payer: String, notesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.clinicianID = clinicianID
            self.procedureCode = procedureCode
            self.bed = bed
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.expiresAtText = expiresAtText
            self.payer = payer
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardRollupView(_ item: BedBoardRollup) -> BedBoardRollupView {
        return BedBoardRollupView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            checksum: item.checksum,
            clinicianID: item.clinicianID,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            facility: item.facility,
            diagnosisCode: item.diagnosisCode,
            expiresAtText: String(item.expiresAt),
            payer: item.payer,
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardRollupViews(_ items: [BedBoardRollup]) -> [BedBoardRollupView] {
        var views: [BedBoardRollupView] = []
        for item in items {
            views.append(toBedBoardRollupView(item))
        }
        return views
    }

    static func sumBedBoardRollupView(_ view: BedBoardRollupView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
