import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution allocation.
    final class SubstitutionAllocationView {
        var code: String
        var label: String
        var dosageMgText: String
        var versionText: String
        var payerText: String
        var attempts: String
        var statusLabel: String

        init(code: String, label: String, dosageMgText: String, versionText: String, payerText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.dosageMgText = dosageMgText
            self.versionText = versionText
            self.payerText = payerText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionAllocationView(_ item: SubstitutionAllocation) -> SubstitutionAllocationView {
        return SubstitutionAllocationView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            versionText: String(item.version),
            payerText: item.payer,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionAllocationViews(_ items: [SubstitutionAllocation]) -> [SubstitutionAllocationView] {
        var views: [SubstitutionAllocationView] = []
        for item in items {
            views.append(toSubstitutionAllocationView(item))
        }
        return views
    }

    static func sumSubstitutionAllocationView(_ view: SubstitutionAllocationView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedDosageMg + Double(parsedVersion) + Double(parsedAttempts)
    }
}
