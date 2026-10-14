import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a primary accession group.
    final class PrimaryAccessionGroupView {
        var code: String
        var label: String
        var externalRefText: String
        var clinicianIDText: String
        var patientRef: String
        var description: String
        var bed: String
        var limit: String
        var statusLabel: String

        init(code: String, label: String, externalRefText: String, clinicianIDText: String, patientRef: String, description: String, bed: String, limit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.externalRefText = externalRefText
            self.clinicianIDText = clinicianIDText
            self.patientRef = patientRef
            self.description = description
            self.bed = bed
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAccessionGroupView(_ item: PrimaryAccessionGroup) -> PrimaryAccessionGroupView {
        return PrimaryAccessionGroupView(
            code: item.code,
            label: item.label,
            externalRefText: item.externalRef,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 40),
            patientRef: item.patientRef,
            description: Kit.Text.truncate(item.description, limit: 120),
            bed: item.bed,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAccessionGroupViews(_ items: [PrimaryAccessionGroup]) -> [PrimaryAccessionGroupView] {
        var views: [PrimaryAccessionGroupView] = []
        for item in items {
            views.append(toPrimaryAccessionGroupView(item))
        }
        return views
    }

    static func sumPrimaryAccessionGroupView(_ view: PrimaryAccessionGroupView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
