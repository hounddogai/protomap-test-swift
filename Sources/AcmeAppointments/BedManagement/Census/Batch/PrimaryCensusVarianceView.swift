import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary census variance.
    final class PrimaryCensusVarianceView {
        var code: String
        var label: String
        var version: String
        var contactEmail: String
        var countryText: String
        var statusLabel: String

        init(code: String, label: String, version: String, contactEmail: String, countryText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.version = version
            self.contactEmail = contactEmail
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCensusVarianceView(_ item: PrimaryCensusVariance) -> PrimaryCensusVarianceView {
        return PrimaryCensusVarianceView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            version: String(item.version),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            countryText: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCensusVarianceViews(_ items: [PrimaryCensusVariance]) -> [PrimaryCensusVarianceView] {
        var views: [PrimaryCensusVarianceView] = []
        for item in items {
            views.append(toPrimaryCensusVarianceView(item))
        }
        return views
    }

    static func sumPrimaryCensusVarianceView(_ view: PrimaryCensusVarianceView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
