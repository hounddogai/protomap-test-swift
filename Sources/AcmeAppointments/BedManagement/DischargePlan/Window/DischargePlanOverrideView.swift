import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan override.
    final class DischargePlanOverrideView {
        var codeText: String
        var nameText: String
        var countryText: String
        var refillsText: String
        var sequenceText: String
        var attempts: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, nameText: String, countryText: String, refillsText: String, sequenceText: String, attempts: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.countryText = countryText
            self.refillsText = refillsText
            self.sequenceText = sequenceText
            self.attempts = attempts
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanOverrideView(_ item: DischargePlanOverride) -> DischargePlanOverrideView {
        return DischargePlanOverrideView(
            codeText: item.code,
            nameText: item.name,
            countryText: item.country,
            refillsText: String(item.refills),
            sequenceText: String(item.sequence),
            attempts: String(item.attempts),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanOverrideViews(_ items: [DischargePlanOverride]) -> [DischargePlanOverrideView] {
        var views: [DischargePlanOverrideView] = []
        for item in items {
            views.append(toDischargePlanOverrideView(item))
        }
        return views
    }

    static func sumDischargePlanOverrideView(_ view: DischargePlanOverrideView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRefills) + Double(parsedSequence) + Double(parsedAttempts)
    }
}
