import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a tiered accession profile.
    final class TieredAccessionProfileView {
        var codeText: String
        var labelText: String
        var procedureCode: String
        var nameText: String
        var refills: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, labelText: String, procedureCode: String, nameText: String, refills: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.procedureCode = procedureCode
            self.nameText = nameText
            self.refills = refills
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAccessionProfileView(_ item: TieredAccessionProfile) -> TieredAccessionProfileView {
        return TieredAccessionProfileView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            nameText: item.name,
            refills: String(item.refills),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAccessionProfileViews(_ items: [TieredAccessionProfile]) -> [TieredAccessionProfileView] {
        var views: [TieredAccessionProfileView] = []
        for item in items {
            views.append(toTieredAccessionProfileView(item))
        }
        return views
    }

    static func sumTieredAccessionProfileView(_ view: TieredAccessionProfileView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedRefills) + parsedMinimum
    }
}
