import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default charge exception.
    final class DefaultChargeExceptionView {
        var codeText: String
        var name: String
        var pinned: String
        var ownerIDText: String
        var timezone: String
        var sequence: String
        var score: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, name: String, pinned: String, ownerIDText: String, timezone: String, sequence: String, score: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.pinned = pinned
            self.ownerIDText = ownerIDText
            self.timezone = timezone
            self.sequence = sequence
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultChargeExceptionView(_ item: DefaultChargeException) -> DefaultChargeExceptionView {
        return DefaultChargeExceptionView(
            codeText: item.code,
            name: item.name,
            pinned: "\(item.pinned)",
            ownerIDText: item.ownerID,
            timezone: item.timezone,
            sequence: String(item.sequence),
            score: String(format: "%.2f", item.score),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultChargeExceptionViews(_ items: [DefaultChargeException]) -> [DefaultChargeExceptionView] {
        var views: [DefaultChargeExceptionView] = []
        for item in items {
            views.append(toDefaultChargeExceptionView(item))
        }
        return views
    }

    static func sumDefaultChargeExceptionView(_ view: DefaultChargeExceptionView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedSequence) + parsedScore
    }
}
