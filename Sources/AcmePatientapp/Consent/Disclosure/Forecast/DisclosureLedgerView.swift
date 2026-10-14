import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure ledger.
    final class DisclosureLedgerView {
        var codeText: String
        var label: String
        var durationMinutes: String
        var visible: String
        var priority: String
        var patientRef: String
        var copay: String
        var procedureCodeText: String
        var statusLabel: String

        init(codeText: String, label: String, durationMinutes: String, visible: String, priority: String, patientRef: String, copay: String, procedureCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.durationMinutes = durationMinutes
            self.visible = visible
            self.priority = priority
            self.patientRef = patientRef
            self.copay = copay
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureLedgerView(_ item: DisclosureLedger) -> DisclosureLedgerView {
        return DisclosureLedgerView(
            codeText: item.code,
            label: item.label,
            durationMinutes: String(item.durationMinutes),
            visible: "\(item.visible)",
            priority: String(item.priority),
            patientRef: item.patientRef,
            copay: String(format: "%.2f", item.copay),
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureLedgerViews(_ items: [DisclosureLedger]) -> [DisclosureLedgerView] {
        var views: [DisclosureLedgerView] = []
        for item in items {
            views.append(toDisclosureLedgerView(item))
        }
        return views
    }

    static func sumDisclosureLedgerView(_ view: DisclosureLedgerView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedPriority) + parsedCopay
    }
}
