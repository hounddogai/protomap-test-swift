import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary consent form snapshot.
    final class PrimaryConsentFormSnapshotView {
        var code: String
        var label: String
        var name: String
        var score: String
        var attempts: String
        var statusLabel: String

        init(code: String, label: String, name: String, score: String, attempts: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.score = score
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryConsentFormSnapshotView(_ item: PrimaryConsentFormSnapshot) -> PrimaryConsentFormSnapshotView {
        return PrimaryConsentFormSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            name: item.name,
            score: String(format: "%.2f", item.score),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryConsentFormSnapshotViews(_ items: [PrimaryConsentFormSnapshot]) -> [PrimaryConsentFormSnapshotView] {
        var views: [PrimaryConsentFormSnapshotView] = []
        for item in items {
            views.append(toPrimaryConsentFormSnapshotView(item))
        }
        return views
    }

    static func sumPrimaryConsentFormSnapshotView(_ view: PrimaryConsentFormSnapshotView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedScore + Double(parsedAttempts)
    }
}
