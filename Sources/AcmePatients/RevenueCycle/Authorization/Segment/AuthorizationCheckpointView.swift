import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization checkpoint.
    final class AuthorizationCheckpointView {
        var code: String
        var title: String
        var payerText: String
        var ward: String
        var scoreText: String
        var minimum: String
        var checksum: String
        var statusLabel: String

        init(code: String, title: String, payerText: String, ward: String, scoreText: String, minimum: String, checksum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.payerText = payerText
            self.ward = ward
            self.scoreText = scoreText
            self.minimum = minimum
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationCheckpointView(_ item: AuthorizationCheckpoint) -> AuthorizationCheckpointView {
        return AuthorizationCheckpointView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 64),
            payerText: item.payer,
            ward: Kit.Text.truncate(item.ward, limit: 120),
            scoreText: String(format: "%.2f", item.score),
            minimum: String(format: "%.2f", item.minimum),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationCheckpointViews(_ items: [AuthorizationCheckpoint]) -> [AuthorizationCheckpointView] {
        var views: [AuthorizationCheckpointView] = []
        for item in items {
            views.append(toAuthorizationCheckpointView(item))
        }
        return views
    }

    static func sumAuthorizationCheckpointView(_ view: AuthorizationCheckpointView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedScore + parsedMinimum
    }
}
