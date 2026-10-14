import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary care protocol rule.
    final class PrimaryCareProtocolRuleView {
        var code: String
        var title: String
        var expiresAtText: String
        var specialty: String
        var attempts: String
        var sequenceText: String
        var score: String
        var margin: String
        var statusLabel: String

        init(code: String, title: String, expiresAtText: String, specialty: String, attempts: String, sequenceText: String, score: String, margin: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.expiresAtText = expiresAtText
            self.specialty = specialty
            self.attempts = attempts
            self.sequenceText = sequenceText
            self.score = score
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCareProtocolRuleView(_ item: PrimaryCareProtocolRule) -> PrimaryCareProtocolRuleView {
        return PrimaryCareProtocolRuleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            expiresAtText: String(item.expiresAt),
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            attempts: String(item.attempts),
            sequenceText: String(item.sequence),
            score: String(format: "%.2f", item.score),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCareProtocolRuleViews(_ items: [PrimaryCareProtocolRule]) -> [PrimaryCareProtocolRuleView] {
        var views: [PrimaryCareProtocolRuleView] = []
        for item in items {
            views.append(toPrimaryCareProtocolRuleView(item))
        }
        return views
    }

    static func sumPrimaryCareProtocolRuleView(_ view: PrimaryCareProtocolRuleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedAttempts) + Double(parsedSequence)
    }
}
