import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential baseline.
    final class CredentialBaselineView {
        var code: String
        var title: String
        var notes: String
        var dosageMg: String
        var endsAt: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, title: String, notes: String, dosageMg: String, endsAt: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notes = notes
            self.dosageMg = dosageMg
            self.endsAt = endsAt
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialBaselineView(_ item: CredentialBaseline) -> CredentialBaselineView {
        return CredentialBaselineView(
            code: item.code,
            title: item.title,
            notes: item.notes,
            dosageMg: String(format: "%.2f", item.dosageMg),
            endsAt: String(item.endsAt),
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialBaselineViews(_ items: [CredentialBaseline]) -> [CredentialBaselineView] {
        var views: [CredentialBaselineView] = []
        for item in items {
            views.append(toCredentialBaselineView(item))
        }
        return views
    }

    static func sumCredentialBaselineView(_ view: CredentialBaselineView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedDosageMg + Double(parsedEndsAt)
    }
}
