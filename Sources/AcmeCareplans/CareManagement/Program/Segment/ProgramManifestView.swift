import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program manifest.
    final class ProgramManifestView {
        var codeText: String
        var name: String
        var acuity: String
        var amountText: String
        var locale: String
        var statusLabel: String

        init(codeText: String, name: String, acuity: String, amountText: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.acuity = acuity
            self.amountText = amountText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toProgramManifestView(_ item: ProgramManifest) -> ProgramManifestView {
        return ProgramManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            acuity: String(item.acuity),
            amountText: String(format: "%.2f", item.amount),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramManifestViews(_ items: [ProgramManifest]) -> [ProgramManifestView] {
        var views: [ProgramManifestView] = []
        for item in items {
            views.append(toProgramManifestView(item))
        }
        return views
    }

    static func sumProgramManifestView(_ view: ProgramManifestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedAcuity) + parsedAmount
    }
}
