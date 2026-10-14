import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending credential preference.
    final class PendingCredentialPreferenceView {
        var code: String
        var name: String
        var sequenceText: String
        var acuity: String
        var specialty: String
        var pinnedText: String
        var cost: String
        var label: String
        var revision: String
        var contactEmailText: String
        var segment: String
        var statusLabel: String

        init(code: String, name: String, sequenceText: String, acuity: String, specialty: String, pinnedText: String, cost: String, label: String, revision: String, contactEmailText: String, segment: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.sequenceText = sequenceText
            self.acuity = acuity
            self.specialty = specialty
            self.pinnedText = pinnedText
            self.cost = cost
            self.label = label
            self.revision = revision
            self.contactEmailText = contactEmailText
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCredentialPreferenceView(_ item: PendingCredentialPreference) -> PendingCredentialPreferenceView {
        return PendingCredentialPreferenceView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            sequenceText: String(item.sequence),
            acuity: String(item.acuity),
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            pinnedText: "\(item.pinned)",
            cost: String(format: "%.2f", item.cost),
            label: item.label,
            revision: String(item.revision),
            contactEmailText: item.contactEmail,
            segment: Kit.Text.truncate(item.segment, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCredentialPreferenceViews(_ items: [PendingCredentialPreference]) -> [PendingCredentialPreferenceView] {
        var views: [PendingCredentialPreferenceView] = []
        for item in items {
            views.append(toPendingCredentialPreferenceView(item))
        }
        return views
    }

    static func sumPendingCredentialPreferenceView(_ view: PendingCredentialPreferenceView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedSequence) + Double(parsedAcuity) + parsedCost
    }
}
