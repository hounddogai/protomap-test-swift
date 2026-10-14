import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default witness preference.
    final class DefaultWitnessPreferenceView {
        var codeText: String
        var nameText: String
        var version: String
        var reviewerText: String
        var ownerID: String
        var allergyText: String
        var clinicianID: String
        var ward: String
        var attemptsText: String
        var threshold: String
        var refills: String
        var statusLabel: String

        init(codeText: String, nameText: String, version: String, reviewerText: String, ownerID: String, allergyText: String, clinicianID: String, ward: String, attemptsText: String, threshold: String, refills: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.version = version
            self.reviewerText = reviewerText
            self.ownerID = ownerID
            self.allergyText = allergyText
            self.clinicianID = clinicianID
            self.ward = ward
            self.attemptsText = attemptsText
            self.threshold = threshold
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultWitnessPreferenceView(_ item: DefaultWitnessPreference) -> DefaultWitnessPreferenceView {
        return DefaultWitnessPreferenceView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            version: String(item.version),
            reviewerText: item.reviewer,
            ownerID: item.ownerID,
            allergyText: item.allergy,
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            ward: item.ward,
            attemptsText: String(item.attempts),
            threshold: String(format: "%.2f", item.threshold),
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultWitnessPreferenceViews(_ items: [DefaultWitnessPreference]) -> [DefaultWitnessPreferenceView] {
        var views: [DefaultWitnessPreferenceView] = []
        for item in items {
            views.append(toDefaultWitnessPreferenceView(item))
        }
        return views
    }

    static func sumDefaultWitnessPreferenceView(_ view: DefaultWitnessPreferenceView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedVersion) + Double(parsedAttempts) + parsedThreshold
    }
}
