import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program digest.
    final class ProgramDigestView {
        var codeText: String
        var name: String
        var maximumText: String
        var copay: String
        var region: String
        var scoreText: String
        var updatedAt: String
        var statusLabel: String

        init(codeText: String, name: String, maximumText: String, copay: String, region: String, scoreText: String, updatedAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.maximumText = maximumText
            self.copay = copay
            self.region = region
            self.scoreText = scoreText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toProgramDigestView(_ item: ProgramDigest) -> ProgramDigestView {
        return ProgramDigestView(
            codeText: item.code,
            name: item.name,
            maximumText: String(format: "%.2f", item.maximum),
            copay: String(format: "%.2f", item.copay),
            region: item.region,
            scoreText: String(format: "%.2f", item.score),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramDigestViews(_ items: [ProgramDigest]) -> [ProgramDigestView] {
        var views: [ProgramDigestView] = []
        for item in items {
            views.append(toProgramDigestView(item))
        }
        return views
    }

    static func sumProgramDigestView(_ view: ProgramDigestView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedMaximum + parsedCopay + parsedScore
    }
}
