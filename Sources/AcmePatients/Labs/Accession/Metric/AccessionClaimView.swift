import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession claim.
    final class AccessionClaimView {
        var code: String
        var name: String
        var allergy: String
        var versionText: String
        var segment: String
        var capacity: String
        var diagnosisCode: String
        var timezoneText: String
        var copay: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, versionText: String, segment: String, capacity: String, diagnosisCode: String, timezoneText: String, copay: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.versionText = versionText
            self.segment = segment
            self.capacity = capacity
            self.diagnosisCode = diagnosisCode
            self.timezoneText = timezoneText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionClaimView(_ item: AccessionClaim) -> AccessionClaimView {
        return AccessionClaimView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            allergy: Kit.Text.truncate(item.allergy, limit: 120),
            versionText: String(item.version),
            segment: Kit.Text.truncate(item.segment, limit: 80),
            capacity: String(item.capacity),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            timezoneText: item.timezone,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionClaimViews(_ items: [AccessionClaim]) -> [AccessionClaimView] {
        var views: [AccessionClaimView] = []
        for item in items {
            views.append(toAccessionClaimView(item))
        }
        return views
    }

    static func sumAccessionClaimView(_ view: AccessionClaimView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedVersion) + Double(parsedCapacity) + parsedCopay
    }
}
