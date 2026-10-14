import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a tiered result policy.
    final class TieredResultPolicyView {
        var code: String
        var title: String
        var source: String
        var nameText: String
        var visible: String
        var specialty: String
        var revisionText: String
        var labelText: String
        var procedureCode: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, title: String, source: String, nameText: String, visible: String, specialty: String, revisionText: String, labelText: String, procedureCode: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.source = source
            self.nameText = nameText
            self.visible = visible
            self.specialty = specialty
            self.revisionText = revisionText
            self.labelText = labelText
            self.procedureCode = procedureCode
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredResultPolicyView(_ item: TieredResultPolicy) -> TieredResultPolicyView {
        return TieredResultPolicyView(
            code: item.code,
            title: item.title,
            source: item.source,
            nameText: item.name,
            visible: "\(item.visible)",
            specialty: item.specialty,
            revisionText: String(item.revision),
            labelText: item.label,
            procedureCode: item.procedureCode,
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredResultPolicyViews(_ items: [TieredResultPolicy]) -> [TieredResultPolicyView] {
        var views: [TieredResultPolicyView] = []
        for item in items {
            views.append(toTieredResultPolicyView(item))
        }
        return views
    }

    static func sumTieredResultPolicyView(_ view: TieredResultPolicyView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRevision) + parsedCeiling
    }
}
