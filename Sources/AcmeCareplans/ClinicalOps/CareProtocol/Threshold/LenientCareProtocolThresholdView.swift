import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient care protocol threshold.
    final class LenientCareProtocolThresholdView {
        var codeText: String
        var name: String
        var procedureCode: String
        var ward: String
        var ownerID: String
        var pinned: String
        var source: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, name: String, procedureCode: String, ward: String, ownerID: String, pinned: String, source: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.procedureCode = procedureCode
            self.ward = ward
            self.ownerID = ownerID
            self.pinned = pinned
            self.source = source
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCareProtocolThresholdView(_ item: LenientCareProtocolThreshold) -> LenientCareProtocolThresholdView {
        return LenientCareProtocolThresholdView(
            codeText: item.code,
            name: item.name,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            ward: item.ward,
            ownerID: item.ownerID,
            pinned: "\(item.pinned)",
            source: item.source,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCareProtocolThresholdViews(_ items: [LenientCareProtocolThreshold]) -> [LenientCareProtocolThresholdView] {
        var views: [LenientCareProtocolThresholdView] = []
        for item in items {
            views.append(toLenientCareProtocolThresholdView(item))
        }
        return views
    }

    static func sumLenientCareProtocolThresholdView(_ view: LenientCareProtocolThresholdView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
