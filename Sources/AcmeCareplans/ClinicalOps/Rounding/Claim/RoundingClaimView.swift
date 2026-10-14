import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding claim.
    final class RoundingClaimView {
        var code: String
        var name: String
        var acuity: String
        var sequence: String
        var updatedAtText: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, acuity: String, sequence: String, updatedAtText: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.sequence = sequence
            self.updatedAtText = updatedAtText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingClaimView(_ item: RoundingClaim) -> RoundingClaimView {
        return RoundingClaimView(
            code: item.code,
            name: item.name,
            acuity: String(item.acuity),
            sequence: String(item.sequence),
            updatedAtText: String(item.updatedAt),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingClaimViews(_ items: [RoundingClaim]) -> [RoundingClaimView] {
        var views: [RoundingClaimView] = []
        for item in items {
            views.append(toRoundingClaimView(item))
        }
        return views
    }

    static func sumRoundingClaimView(_ view: RoundingClaimView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedSequence) + Double(parsedUpdatedAt)
    }
}
