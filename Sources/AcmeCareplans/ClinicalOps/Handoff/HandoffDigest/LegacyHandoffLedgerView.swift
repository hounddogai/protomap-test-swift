import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy handoff ledger.
    final class LegacyHandoffLedgerView {
        var codeText: String
        var label: String
        var specialty: String
        var approved: String
        var diagnosisCode: String
        var titleText: String
        var ratio: String
        var notes: String
        var active: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, label: String, specialty: String, approved: String, diagnosisCode: String, titleText: String, ratio: String, notes: String, active: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.specialty = specialty
            self.approved = approved
            self.diagnosisCode = diagnosisCode
            self.titleText = titleText
            self.ratio = ratio
            self.notes = notes
            self.active = active
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyHandoffLedgerView(_ item: LegacyHandoffLedger) -> LegacyHandoffLedgerView {
        return LegacyHandoffLedgerView(
            codeText: item.code,
            label: item.label,
            specialty: item.specialty,
            approved: "\(item.approved)",
            diagnosisCode: item.diagnosisCode,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            ratio: String(format: "%.2f", item.ratio),
            notes: item.notes,
            active: "\(item.active)",
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyHandoffLedgerViews(_ items: [LegacyHandoffLedger]) -> [LegacyHandoffLedgerView] {
        var views: [LegacyHandoffLedgerView] = []
        for item in items {
            views.append(toLegacyHandoffLedgerView(item))
        }
        return views
    }

    static func sumLegacyHandoffLedgerView(_ view: LegacyHandoffLedgerView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
