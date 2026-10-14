import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional care protocol digest.
    final class RegionalCareProtocolDigestView {
        var code: String
        var name: String
        var archivedText: String
        var ward: String
        var diagnosisCodeText: String
        var updatedAt: String
        var patientRefText: String
        var ratio: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, archivedText: String, ward: String, diagnosisCodeText: String, updatedAt: String, patientRefText: String, ratio: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archivedText = archivedText
            self.ward = ward
            self.diagnosisCodeText = diagnosisCodeText
            self.updatedAt = updatedAt
            self.patientRefText = patientRefText
            self.ratio = ratio
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCareProtocolDigestView(_ item: RegionalCareProtocolDigest) -> RegionalCareProtocolDigestView {
        return RegionalCareProtocolDigestView(
            code: item.code,
            name: item.name,
            archivedText: "\(item.archived)",
            ward: item.ward,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            updatedAt: String(item.updatedAt),
            patientRefText: item.patientRef,
            ratio: String(format: "%.2f", item.ratio),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCareProtocolDigestViews(_ items: [RegionalCareProtocolDigest]) -> [RegionalCareProtocolDigestView] {
        var views: [RegionalCareProtocolDigestView] = []
        for item in items {
            views.append(toRegionalCareProtocolDigestView(item))
        }
        return views
    }

    static func sumRegionalCareProtocolDigestView(_ view: RegionalCareProtocolDigestView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedUpdatedAt) + parsedRatio + Double(parsedEndsAt)
    }
}
