import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution digest.
    final class SubstitutionDigestView {
        var codeText: String
        var name: String
        var acuity: String
        var maximumText: String
        var floorValue: String
        var diagnosisCode: String
        var revision: String
        var categoryText: String
        var endsAt: String
        var phone: String
        var statusLabel: String

        init(codeText: String, name: String, acuity: String, maximumText: String, floorValue: String, diagnosisCode: String, revision: String, categoryText: String, endsAt: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.acuity = acuity
            self.maximumText = maximumText
            self.floorValue = floorValue
            self.diagnosisCode = diagnosisCode
            self.revision = revision
            self.categoryText = categoryText
            self.endsAt = endsAt
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionDigestView(_ item: SubstitutionDigest) -> SubstitutionDigestView {
        return SubstitutionDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            acuity: String(item.acuity),
            maximumText: String(format: "%.2f", item.maximum),
            floorValue: String(format: "%.2f", item.floorValue),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            revision: String(item.revision),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            endsAt: String(item.endsAt),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionDigestViews(_ items: [SubstitutionDigest]) -> [SubstitutionDigestView] {
        var views: [SubstitutionDigestView] = []
        for item in items {
            views.append(toSubstitutionDigestView(item))
        }
        return views
    }

    static func sumSubstitutionDigestView(_ view: SubstitutionDigestView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedAcuity) + parsedMaximum + parsedFloorValue
    }
}
