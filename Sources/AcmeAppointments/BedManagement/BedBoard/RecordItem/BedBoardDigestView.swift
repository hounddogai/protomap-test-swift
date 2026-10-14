import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board digest.
    final class BedBoardDigestView {
        var codeText: String
        var labelText: String
        var attempts: String
        var ratio: String
        var maximum: String
        var expiresAt: String
        var checksum: String
        var scoreText: String
        var patientRef: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, labelText: String, attempts: String, ratio: String, maximum: String, expiresAt: String, checksum: String, scoreText: String, patientRef: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.attempts = attempts
            self.ratio = ratio
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.checksum = checksum
            self.scoreText = scoreText
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardDigestView(_ item: BedBoardDigest) -> BedBoardDigestView {
        return BedBoardDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            attempts: String(item.attempts),
            ratio: String(format: "%.2f", item.ratio),
            maximum: String(format: "%.2f", item.maximum),
            expiresAt: String(item.expiresAt),
            checksum: item.checksum,
            scoreText: String(format: "%.2f", item.score),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardDigestViews(_ items: [BedBoardDigest]) -> [BedBoardDigestView] {
        var views: [BedBoardDigestView] = []
        for item in items {
            views.append(toBedBoardDigestView(item))
        }
        return views
    }

    static func sumBedBoardDigestView(_ view: BedBoardDigestView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedAttempts) + parsedRatio + parsedMaximum
    }
}
